require 'kaching/version'
require 'active_record'
require 'kaching/model_additions'
require 'kaching/storage_providers/memory'
require 'kaching/storage_providers/redis'
if defined? Rails
  require 'kaching/railtie'
else
  ActiveRecord::Base.send :include, Kaching::ModelAdditions
end

module Kaching
end
