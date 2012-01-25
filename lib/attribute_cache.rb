require 'attribute_cache/version'
require 'active_record'
require 'attribute_cache/model_additions'
require 'attribute_cache/storage_providers/memory'
require 'attribute_cache/storage_providers/redis'
if defined? Rails
  require 'attribute_cache/railtie'
else
  ActiveRecord::Base.send :include, AttributeCache::ModelAdditions
end

module AttributeCache
end
