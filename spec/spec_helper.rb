require 'attribute_cache'
require 'support/db/connection'
require 'support/db/models'

RSpec.configure do |config|
  config.mock_with :rspec
  #  ==========================> Redis test configuration

  root = File.dirname(__FILE__)
  REDIS_PID = File.join(root, "tmp/pids/redis-test.pid")
  REDIS_CACHE_PATH = File.join(root, "tmp/cache/")

  FileUtils.mkdir_p File.join(root, "tmp/pids")
  FileUtils.mkdir_p File.join(root, "tmp/cache")

  config.before(:suite) do
    redis_options = {
      "daemonize"     => 'yes',
      "pidfile"       => REDIS_PID,
      "port"          => 9726,
      "timeout"       => 300,
      "save 900"      => 1,
      "save 300"      => 1,
      "save 60"       => 10000,
      "dbfilename"    => "dump.rdb",
      "dir"           => REDIS_CACHE_PATH,
      "loglevel"      => "debug",
      "logfile"       => "stdout",
      "databases"     => 16
    }.map { |k, v| "#{k} #{v}" }.join('\n')
    cmd = "echo '#{redis_options}' | redis-server -"
    system cmd
    
    
    uri = URI.parse("http://localhost:9726")
    $redis = Redis.new(host: uri.host, port: uri.port)
    
    AttributeCache::StorageProviders.Redis = $redis
  end
    
  config.after(:suite) do
    %x{
      cat #{REDIS_PID} | xargs kill -QUIT
      rm -f #{REDIS_CACHE_PATH}dump.rdb
      rm -f #{REDIS_PID}
    }
  end
  
  config.before(:each) do
    $redis.flushdb
  end
end