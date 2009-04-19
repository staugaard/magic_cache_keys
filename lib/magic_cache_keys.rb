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
        connection.execute('SET group_concat_max_len = 1048576')
        if options[:conditions] && options[:conditions].is_a?(String) && options[:conditions].strip.upcase.starts_with?('SELECT')
          hash_sql = options[:conditions].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{cache_key_select} FROM" }
        else
          options[:select] = cache_key_select(options.delete(:order) || scope(:find, :order))
          hash_sql = construct_finder_sql(options)
        end
        
        "#{model_name.cache_key}/#{connection.select_value(hash_sql) || 'empty'}"
      end
      
      def cache_key_select(order = nil)
        "MD5(CONCAT(GROUP_CONCAT(CONV(#{quoted_table_name}.#{connection.quote_column_name(primary_key)},10,36)#{ ' ORDER BY ' + order unless order.blank?}), MAX(#{quoted_table_name}.#{connection.quote_column_name('updated_at')}))) as cached_key"
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
