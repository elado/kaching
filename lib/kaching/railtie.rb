module Kaching
  class Railtie < Rails::Railtie
    initializer 'attrubute_cache.model_additions' do
      ActiveSupport.on_load :active_record do
        include ModelAdditions
      end
    end
  end
end
