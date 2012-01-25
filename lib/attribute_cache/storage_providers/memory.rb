module AttributeCache
  module StorageProviders
    class Memory
      class << self
        def data
          @data ||= {}
        end
        
        def get(key)
          AttributeCache.logger.info "CACHE read #{key} = #{data[key]}"
          data[key]
        end
        
        def set(key, value)
          AttributeCache.logger.info "CACHE write #{key} = #{value}"
          data[key] = value
        end
        
        def del(key)
          data.delete(key)
        end
        
        def fetch(key, &block)
          AttributeCache.logger.info "CACHE fetch #{key} = #{data[key].inspect}"
          get(key) || set(key, block.call)
        end
        
        def incr(key)
          data[key] ||= 0
          AttributeCache.logger.info "CACHE inc #{key} = #{data[key] + 1}"
          data[key] += 1
        end
        
        def decr(key)
          data[key] ||= 0
          AttributeCache.logger.info "CACHE dec #{key} = #{data[key] - 1}"
          data[key] -= 1
        end
      end
    end
  end
end
