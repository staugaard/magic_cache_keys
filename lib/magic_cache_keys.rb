ActiveRecord::Base.valid_keys_for_has_many_association << :cache_key

module ActiveRecord
  module CacheKeyCaching
    module AssociationCollectionExtension
      def cache_key
        key = @reflection.klass.cache_key(scope(:find))
        
        new_records_count = @target.select { |r| r.new_record? }.size

        key << "/#{new_records_count}new" if new_records_count > 0
        
        key
      end
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
      def cache_key(options = {})
        order = options.delete(:order) || scope(:find, :order)
        opts = {:select => "MD5(CONCAT(GROUP_CONCAT(CONV(#{quoted_table_name}.#{connection.quote_column_name(primary_key)},10,36)#{ ' ORDER BY ' + order unless order.blank?}), MAX(#{table_name}.updated_at))) as cached_key"}.reverse_merge(options)
        
        connection.execute('SET group_concat_max_len = 1048576')
        "#{model_name.cache_key}/#{connection.select_value(construct_finder_sql(opts)) || 'empty'}"
      end

      def has_many_with_cache_key(association_id, options = {}, &extension)
        options[:extend] ||= []
        options[:extend] = [*options[:extend]]
        options[:extend] << ActiveRecord::CacheKeyCaching::AssociationCollectionExtension
        
        has_many_without_cache_key(association_id, options, &extension)
      end
      alias_method_chain :has_many, :cache_key
    end
  end
end
