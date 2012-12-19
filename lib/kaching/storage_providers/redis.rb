require 'redis'

module Kaching
  module StorageProviders
    def self.Redis
      if @redis && !@redis.respond_to?(:fetch)
        def @redis.fetch(key, &block)
          value = get(key)
      
          if !value
            value = block.call
            set(key, value)
          end
      
          value
        end
      end
      
      @redis
    end
    
    def self.Redis=(adapter)
      @redis = adapter
    end
  end
end
