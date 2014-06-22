module Kaching
  module CacheCounter
    def cache_counter(attribute, options = {})
      options = {}.merge(options || {})
        
      container_class = self
        
      count_method_name = options[:count_method_name] || "#{attribute.to_s}_count"
      reset_count_method_name = "reset_count_cache_#{attribute.to_s}!"
      
      Kaching.logger.info "DEFINE #{container_class.name}##{count_method_name}"
        
      container_class.send :define_method, count_method_name do
        value = Kaching.cache_store.fetch(kaching_key(attribute, :count)) {
          value = (block_given? ? yield(self) : self.send(attribute))
          value = value.count unless value.is_a?(Fixnum)
          
          Kaching.logger.info "FIRST FETCH #{value}"
          value
        }.to_i

        Kaching.logger.info "CALL #{container_class.name}##{count_method_name} = #{value}"

        value
      end
      
      container_class.send :define_method, reset_count_method_name do
        Kaching.cache_store.del(self.kaching_key(attribute, :count))
      end

      container_class.send(:after_commit) do
        if self.destroyed?
          Kaching.cache_store.del(self.kaching_key(attribute, :count))
        end
      end
        
      countable_class = options[:class_name].constantize if options[:class_name]
      countable_class ||= attribute.to_s.singularize.classify.constantize
        
      Kaching.logger.info "COUNTABLE DEFINE #{countable_class} after_commit"
        
      foreign_key = Kaching._extract_foreign_key_from(attribute, options, container_class)

      after_commit_method_name = "after_commit_#{count_method_name}"
      countable_class.send(:define_method, after_commit_method_name) do |action|
        begin
          Kaching.logger.info "COUNTABLE #{countable_class.name} after_commit foreign_key = #{foreign_key}"

          belongs_to_item = self.send(foreign_key)
        
          return unless belongs_to_item

          Kaching.logger.info " > COUNTABLE after_commit #{countable_class.name} belongs_to(#{foreign_key}) = #{belongs_to_item.class.name}##{belongs_to_item.id} | #{action.inspect}"
          
          counter_key = belongs_to_item.kaching_key(attribute, :count)
          
          if !Kaching.cache_store.exists(counter_key)
            belongs_to_item.send(count_method_name) # get fresh count from db
          else
            case action
            when :create
              Kaching.logger.info "  > COUNTABLE INCR #{counter_key}"
          
              Kaching.cache_store.incr(counter_key)
            when :destroy
              Kaching.logger.info "  > COUNTABLE DECR #{counter_key}"

              Kaching.cache_store.decr(counter_key)
            end
          end
        rescue
          puts $!.message
          puts $!.backtrace.join("\n")
          raise $!
        end
      end

      countable_class.send(:after_commit) do
        action = if self.send(:transaction_include_any_action?, [:create])
          :create
        elsif self.destroyed?
          :destroy
        end

        self.send(after_commit_method_name, action) if action
      end
    end
  end
end
