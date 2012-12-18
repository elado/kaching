ActiveRecord::Base.configurations = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.establish_connection('sqlite3')

require 'support/db/schema'