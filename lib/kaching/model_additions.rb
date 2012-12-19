require 'logger'
require 'kaching/cache_counter'
require 'kaching/cache_list'

module Kaching
  # def self.attributes
  #   @attributes ||= []
  # end

  def self.cache_store
    Kaching::StorageProviders.Redis
  end
  
  def self.logger
    @logger ||= begin
      logger = Logger.new(ENV['ATTRIBUTE_CACHE_LOG'] ? $stdout : '/dev/null')
      logger.level = Logger::INFO
      logger
    end
  end
  
  def self._extract_foreign_key_from(attribute, options, container_class)
    foreign_key = options[:foreign_key]
            
    if !foreign_key
      reflection = container_class.reflections[attribute]
      foreign_key = reflection.options[:foreign_key] if reflection
    end

    foreign_key = if foreign_key
      foreign_key.gsub(/_id$/, "")
    else
      container_class.name.underscore.singularize
    end
    
    foreign_key
  end
  
  module ModelAdditions
    module ClassMethods
      include CacheCounter
      include CacheList
    end
  
    module InstanceMethods
      def kaching_key(attribute, type)
        "Kaching::#{type}::#{self.class.name.underscore.singularize}::#{self.id}::#{attribute}"
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
