ActiveRecord::Base.valid_keys_for_has_many_association << :cache_key

module ActiveRecord
  module Reflection
    class AssociationReflection < MacroReflection
      def cache_key_column
        if options[:cache_key] == true
          "#{@name}_cache_key"
        elsif options[:cache_key]
          options[:cache_key]
        end
      end
    end
  end
  
  module CacheKeyCaching
    module AssociationCollectionExtension
      def cache_key
        if @owner.attribute_present?(@reflection.cache_key_column)
          key = @owner[@reflection.cache_key_column]
        else
          key = update_cache_key
        end
        
        new_records_count = @target.select { |r| r.new_record? }.size
        
        if new_records_count > 0
          key + "/#{new_records_count}new"
        else
          key.dup
        end
      end
      
      def update_cache_key
        options = {:conditions => sanitize_sql({@reflection.primary_key_name => @owner.id})}
        options[:conditions] << " AND (#{conditions})" if conditions
        
        if @reflection.options[:order]
          options[:order] = @reflection.options[:order]
        end
        construct_find_options!(options)
        merge_options_from_reflection!(options)

        key = @reflection.klass.collection_cache_key(options)

        if @owner.class.column_names.include?(@reflection.cache_key_column)
          @owner.class.update_all("#{@reflection.cache_key_column} = '#{key}'", "#{@owner.class.primary_key} = #{@owner.id}")
          @owner[@reflection.cache_key_column] = key
        end
        
        key
      end
    end
    
    class AssociationCollectionUpdater
      def initialize(reflection)
        @reflection = reflection
      end
      
      def after_save(record)
        if record.changed?
          owner_ids = record.send(:attribute_change, @reflection.primary_key_name)
          owner_ids ||= [record[@reflection.primary_key_name]]

          @reflection.active_record.find(owner_ids.compact).each do |owner|
            owner.send(@reflection.name).update_cache_key
          end
        end
      end
      alias_method :after_destroy, :after_save
    end
  end
  
  class Base
    def cache_key_with_associations(*include_associations)
      parts = [cache_key_without_associations]
      include_associations.sort! {|a1, a2| a1.to_s <=> a2.to_s}
      parts += include_associations.map {|a| self.send(a).cache_key }
      parts.join('/')
    end
    alias_method_chain :cache_key, :associations
    
    class << self
      def collection_cache_key(options = {})
        order = options.delete(:order) || scope(:find, :order)
        opts = {:select => "MD5(CONCAT(GROUP_CONCAT(CONV(id,10,36)#{ ' ORDER BY ' + order unless order.blank?}), MAX(updated_at))) as cached_key"}.reverse_merge(options)
        
        connection.execute('SET group_concat_max_len = 1048576')
        "#{model_name.cache_key}/#{connection.select_value(construct_finder_sql(opts)) || 'empty'}"
      end

      def has_many_with_cache_key(association_id, options = {}, &extension)
        options[:extend] ||= []
        options[:extend] = [*options[:extend]]
        options[:extend] << ActiveRecord::CacheKeyCaching::AssociationCollectionExtension
        
        has_many_without_cache_key(association_id, options, &extension)
        
        reflection = reflect_on_association(association_id)

        if reflection.cache_key_column
          updater = ActiveRecord::CacheKeyCaching::AssociationCollectionUpdater.new(reflection)
          reflection.klass.after_save(updater)
          reflection.klass.after_destroy(updater)
        end
      end
      alias_method_chain :has_many, :cache_key
    end
  end
end
