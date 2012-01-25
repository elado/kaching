require 'logger'

module AttributeCache
  # def self.attributes
  #   @attributes ||= []
  # end

  def self.cache_store
    AttributeCache::StorageProviders.Redis
  end
  
  def self.logger
    @logger ||= Logger.new(ENV['ATTRIBUTE_CACHE_LOG'] ? $stdout : '/dev/null')
  end
  
  module ModelAdditions
    module ClassMethods
      def cache_counter(attribute, options = {})
        # AttributeCache.attributes << {
        #   attribute: attribute,
        #   options: options
        # }
        # 
        # puts AttributeCache.attributes
        
        count_method_name = "#{attribute.to_s.singularize}_count"
        
        AttributeCache.logger.info "DEFINE #{self.name}##{count_method_name}"
        
        self.send :define_method, count_method_name do
          AttributeCache.logger.info "CALL count_method_name = #{count_method_name}"
          
          AttributeCache.cache_store.fetch(attribute_cache_key(attribute, :count)) {
            value = block_given? ? yield(self) : self.send(attribute).count
            AttributeCache.logger.info "FIRST FETCH #{value}"
            value
          }.to_i
        end

        self.send(:after_commit) do
          if self.destroyed?
            AttributeCache.cache_store.del(counter_key)
          end
        end

        container_class = self
        
        countable_class = options[:class_name].constantize if options[:class_name]
        countable_class ||= attribute.to_s.singularize.classify.constantize
        
        AttributeCache.logger.info "MODEL DEFINE #{countable_class} after_commit"
        
        # countable_class.send(:after_create) do
        #   AttributeCache.logger.info "MODEL :after_create"
        #   
        #   foreign_key = container_class.reflections[attribute].options[:foreign_key]
        #   foreign_key = if foreign_key
        #     foreign_key.gsub(/_id$/, "")
        #   else
        #     container_class.name.underscore.singularize
        #   end
        #   
        #   belongs_to_item = self.send(foreign_key) # TODO - or from associaction options
        #   AttributeCache.logger.info "MODEL :after_create (#{belongs_to_item.class.name})"
        #   
        #   return unless belongs_to_item
        #   
        #   counter_key = belongs_to_item.attribute_cache_key(attribute, :count)
        #   
        #   AttributeCache.logger.info " > MODEL :after_create"
        # 
        #   AttributeCache.logger.info "INCR #{counter_key}"
        #     
        #   AttributeCache.cache_store.incr(counter_key)
        # end
        
        countable_class.send(:after_commit) do
          begin
            reflection = container_class.reflections[attribute]
            foreign_key = reflection.options[:foreign_key] if reflection
            foreign_key = if foreign_key
              foreign_key.gsub(/_id$/, "")
            else
              container_class.name.underscore.singularize
            end

            belongs_to_item = self.send(foreign_key) # TODO - or from associaction options
            AttributeCache.logger.info "MODEL :after_create (#{belongs_to_item.class.name})"
          
            return unless belongs_to_item
          
            created = self.send(:transaction_include_action?, :create)
            destroyed = self.destroyed?
            
            counter_key = belongs_to_item.attribute_cache_key(attribute, :count)
          
            AttributeCache.logger.info " > MODEL after_commit #{created ? 'created' : destroyed ? 'destroyed' : 'none'}"
        
            if created
              AttributeCache.logger.info "INCR #{counter_key}"
            
              AttributeCache.cache_store.incr(counter_key)
            elsif destroyed
              AttributeCache.logger.info "DECR #{counter_key}"
        
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
  
    module InstanceMethods
      def attribute_cache_key(attribute, type)
        "AttributeCache::#{self.class.name.underscore.singularize}::#{self.id}::#{attribute}::#{type}"
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
