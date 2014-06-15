module Kaching
  module CacheList
    def cache_list(attribute, options = {})
      container_class = self
      
      if block_given?
        self.cache_counter attribute, options do |item|
          yield(self)
        end
      else
        self.cache_counter attribute, options
      end

      options = {
        method_verb:                    nil,
        list_method_name:               attribute.to_s,
        item_key:                       :item,
        polymorphic:                    false,
        add_alter_methods:              true,
        reset_cache_method_name:        "reset_list_cache_#{attribute}!",
        reset_count_cache_method_name:  "reset_count_cache_#{attribute}!"
      }.merge(options || {})

      if options[:method_verb]
        options = {
          add_method_name:                "#{options[:method_verb]}!",
          remove_method_name:             "un#{options[:method_verb]}!",
          exists_method_name:             "#{options[:method_verb]}s?",
          toggle_method_name:             "toggle_#{options[:method_verb]}!",
        }.merge(options)
      else
        singularized_attribute = attribute.to_s.singularize
        options = {
          add_method_name:                "add_#{singularized_attribute}!",
          remove_method_name:             "remove_#{singularized_attribute}!",
          exists_method_name:             "has_#{singularized_attribute}?",
          toggle_method_name:             "toggle_#{singularized_attribute}!",
        }.merge(options)
      end
      
      Kaching.logger.info { "LIST NEW #{self.name} #{options}" }

      list_class = options[:class_name].constantize if options[:class_name]
      list_class ||= attribute.to_s.singularize.classify.constantize

      item_key_id = "#{options[:item_key]}_id"
      
      if options[:polymorphic]
        item_key_type = "#{options[:item_key]}_type"
      end

      if options[:add_alter_methods]
        container_class.send :define_method, options[:add_method_name] do |*args|
          item, values = args
          Kaching.logger.info { "LIST ADD #{self.class.name}##{self.id} #{item.class.name}##{item.id}" }
          
          values = values ? values.dup : {}
          
          values.merge!(options[:item_key] => item)
          values.merge!(options[:create_options]) if options[:create_options]
          
          return nil if self.send(options[:exists_method_name], item)

          list_item = list_class.new(values) 
          self.send(options[:list_method_name]) << list_item
          list_item
        end

        container_class.send :define_method, options[:remove_method_name] do |item|
          Kaching.logger.info { "LIST REMOVE #{self.class.name}##{self.id} #{item.class.name}##{item.id}" }

          where = { item_key_id => item.id }
        
          if options[:polymorphic]
            where[item_key_type] = item.class.name
          end
        
          self.send(options[:list_method_name]).where(where).destroy_all
          
          nil
        end
      
        container_class.send(:define_method, options[:toggle_method_name]) do |*args|
          item, state = args
  
          return unless item
        
          if state.nil?
            state = !self.send(options[:exists_method_name], item)
          end
        
          if state
            self.send(options[:add_method_name], item)
          else
            self.send(options[:remove_method_name], item)
          end
        end
      end
      
      container_class.send(:define_method, options[:exists_method_name]) do |item|
        return false if item == self
        
        hash_key = self.kaching_key(attribute, :list)
        
        if Kaching.cache_store.hexists(hash_key, "created")
          Kaching.logger.info { "USING CREATED #{hash_key}" }
          Kaching.cache_store.hexists hash_key, item.id.to_s
        else
          Kaching.logger.info { "NOT CREATED - CREATING #{hash_key}" }
          
          # fetch all ids
          query = block_given? ? yield(self) : self.send(options[:list_method_name])
          all_ids = container_class.connection.select_values(query.select(item_key_id).to_sql)

          Kaching.logger.info { "FETCH all_ids = #{all_ids.length} | #{all_ids}" }

          no_ids = all_ids.empty?

          ids_with_values_for_hash = all_ids.map { |id|
            [ id, 1 ]
          }.flatten

          ids_with_values_for_hash << "created" << 1
          
          # store them with "created" key. "created" means that hash was created and it's not only empty.
          Kaching.cache_store.send :hmset, *[hash_key, ids_with_values_for_hash].flatten
          
          if no_ids
            false
          else
            all_ids.include?(item.id)
          end
        end
      end
      
      container_class.send :define_method, options[:reset_cache_method_name] do
        Kaching.cache_store.del(self.kaching_key(attribute, :list))
        
        self.send(options[:reset_count_cache_method_name]) if self.respond_to?(options[:reset_count_cache_method_name])
      end

      container_class.send(:after_commit) do
        if self.destroyed?
          Kaching.cache_store.del(self.kaching_key(attribute, :list))
        end
      end
      
      foreign_key = Kaching._extract_foreign_key_from(attribute, options, container_class)
      
      after_commit_method_name = "after_commit_list_#{attribute}"
      list_class.send(:define_method, after_commit_method_name) do |action|
        begin
          Kaching.logger.info { "LIST #{list_class.name} after_commit foreign_key = #{foreign_key}" }
      
          belongs_to_item = self.send(foreign_key)

          return unless belongs_to_item

          hash_key = belongs_to_item.kaching_key(attribute, :list)
          
          # don't bother managing the list because it's not created yet. let the has_item?() build it with all items, and then on creation it'll update the list
          return unless Kaching.cache_store.hexists(hash_key, "created")
          
          Kaching.logger.info { " > LIST after_commit #{list_class.name} belongs_to(#{foreign_key}) = #{belongs_to_item.class.name}##{belongs_to_item.id} #{action.inspect}" }

          case action
          when :create
            Kaching.logger.info { "  > LIST SET #{hash_key} #{self.class.name}##{self.id} type = #{Kaching.cache_store.type(hash_key)}" }
            
            Kaching.cache_store.hset(hash_key, self.send(item_key_id), 1)
          when :destroy
            Kaching.logger.info { "  > LIST DEL #{hash_key}" }
      
            Kaching.cache_store.hdel(hash_key, self.send(item_key_id))
          end
        rescue
          puts $!.message
          puts $!.backtrace.join("\n")
          raise $!
        end
      end
      
      list_class.send(:after_commit) do
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
