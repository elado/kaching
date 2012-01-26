module AttributeCache
  module CacheList
    def cache_list(attribute, options = {})
      container_class = self
      
      self.cache_counter attribute, options

      options = {
        add_method_name:          "add_#{attribute.to_s.singularize}!",
        remove_method_name:       "remove_#{attribute.to_s.singularize}!",
        exists_method_name:       "has_#{attribute.to_s.singularize}?",
        reset_cache_method_name:  "reset_cache_#{attribute.to_s}!",
        list_method_name:         attribute.to_s,
        item_key:                 :item,
        polymorphic:              false,
      }.merge(options || {})

      list_class = options[:class_name].constantize if options[:class_name]
      list_class ||= attribute.to_s.singularize.classify.constantize

      item_key_id = "#{options[:item_key]}_id"
      
      if options[:polymorphic]
        item_key_type = "#{options[:item_key]}_type"
      end

      container_class.send :define_method, options[:add_method_name] do |item|
        AttributeCache.logger.info { "LIST ADD #{self.class.name}##{self.id} #{item.class.name}##{item.id}" }
        self.send(options[:list_method_name]) << list_class.new(options[:item_key] => item) unless self.send(options[:exists_method_name], item)
      end

      container_class.send :define_method, options[:remove_method_name] do |item|
        AttributeCache.logger.info { "LIST REMOVE #{self.class.name}##{self.id} #{item.class.name}##{item.id}" }

        where = { item_key_id => item.id }
        
        if options[:polymorphic]
          where[item_key_type] = item.class.name
        end
        
        self.send(options[:list_method_name]).where(where).destroy_all
      end
      
      container_class.send(:define_method, options[:exists_method_name]) do |item|
        hash_key = self.attribute_cache_key(attribute, :list)
        
        if AttributeCache.cache_store.hexists(hash_key, "created")
          AttributeCache.logger.info { "USING CREATED #{hash_key}" }
          AttributeCache.cache_store.hexists hash_key, item.id.to_s
        else
          AttributeCache.logger.info { "NOT CREATED - CREATING #{hash_key}" }
          
          # fetch all ids
          all_ids = container_class.connection.select_values(self.send(options[:list_method_name]).select(item_key_id).to_sql)

          AttributeCache.logger.info { "FETCH all_ids = #{all_ids.length} | #{all_ids}" }

          all_ids = all_ids.map { |id|
            [ id, 1 ]
          }.flatten

          no_ids = all_ids.empty?

          all_ids << "created" << 1
          
          # store them with "created" key. "created" means that hash was created and it's not only empty.
          AttributeCache.cache_store.send :hmset, *[hash_key, all_ids].flatten
          
          if no_ids
            false
          else
            all_ids.include?(item.id)
          end
        end
      end
      
      container_class.send :define_method, options[:reset_cache_method_name] do
        AttributeCache.cache_store.del(self.attribute_cache_key(attribute, :list))
      end

      container_class.send(:after_commit) do
        if self.destroyed?
          AttributeCache.cache_store.del(self.attribute_cache_key(attribute, :list))
        end
      end
      
      foreign_key = AttributeCache._extract_foreign_key_from(attribute, options, container_class)
      
      list_class.send(:after_commit) do
        begin
          AttributeCache.logger.info { "LIST #{list_class.name} after_commit foreign_key = #{foreign_key}" }
      
          belongs_to_item = self.send(foreign_key)
          
          return unless belongs_to_item
          
          created = self.send(:transaction_include_action?, :create)
          destroyed = self.destroyed?

          hash_key = belongs_to_item.attribute_cache_key(attribute, :list)
          
          # don't bother managing the list because it's not created yet. let the has_item?() build it with all items, and then on creation it'll update the list
          return unless AttributeCache.cache_store.hexists(hash_key, "created")
          
          AttributeCache.logger.info { " > LIST after_commit #{list_class.name} belongs_to(#{foreign_key}) = #{belongs_to_item.class.name}##{belongs_to_item.id} #{created ? 'created' : destroyed ? 'destroyed' : 'none'}" }
        
          if created
            AttributeCache.logger.info { "  > LIST SET #{hash_key} #{self.class.name}##{self.id} type = #{AttributeCache.cache_store.type(hash_key)}" }
            
            AttributeCache.cache_store.hset(hash_key, self.send(item_key_id), 1)
          elsif destroyed
            AttributeCache.logger.info { "  > LIST DEL #{hash_key}" }
      
            AttributeCache.cache_store.hdel(hash_key, self.send(item_key_id))
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
