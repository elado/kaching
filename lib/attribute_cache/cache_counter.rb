module AttributeCache
  module CacheCounter
    def cache_counter(attribute, options = {})
      options = {}.merge(options || {})
        
      container_class = self
        
      count_method_name = options[:method_name] || "#{attribute.to_s}_count"
        
      AttributeCache.logger.info "DEFINE #{container_class.name}##{count_method_name}"
        
      container_class.send :define_method, count_method_name do
        value = AttributeCache.cache_store.fetch(attribute_cache_key(attribute, :count)) {
          value = block_given? ? yield(self) : self.send(attribute).count
          AttributeCache.logger.info "FIRST FETCH #{value}"
          value
        }.to_i

        AttributeCache.logger.info "CALL #{container_class.name}##{count_method_name} = #{value}"
          
        value
      end

      container_class.send(:after_commit) do
        if self.destroyed?
          AttributeCache.cache_store.del(self.attribute_cache_key(attribute, :count))
        end
      end
        
      countable_class = options[:class_name].constantize if options[:class_name]
      countable_class ||= attribute.to_s.singularize.classify.constantize
        
      AttributeCache.logger.info "COUNTABLE DEFINE #{countable_class} after_commit"
        
      foreign_key = AttributeCache._extract_foreign_key_from(attribute, options, container_class)
        
      countable_class.send(:after_commit) do
        begin
          AttributeCache.logger.info "COUNTABLE #{countable_class.name} after_commit foreign_key = #{foreign_key}"

          belongs_to_item = self.send(foreign_key)
          
          return unless belongs_to_item

          created = self.send(:transaction_include_action?, :create)
          destroyed = self.destroyed?
    
          AttributeCache.logger.info " > COUNTABLE after_commit #{countable_class.name} belongs_to(#{foreign_key}) = #{belongs_to_item.class.name}##{belongs_to_item.id} | #{created ? 'created' : destroyed ? 'destroyed' : 'none'}"
            
          counter_key = belongs_to_item.attribute_cache_key(attribute, :count)
        
          if created
            AttributeCache.logger.info "  > COUNTABLE INCR #{counter_key}"
            
            AttributeCache.cache_store.incr(counter_key)
          elsif destroyed
            AttributeCache.logger.info "  > COUNTABLE DECR #{counter_key}"

            AttributeCache.cache_store.decr(counter_key)
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace
          raise
        end
      end
    end
  end
end
