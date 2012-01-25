uri = URI.parse("http://localhost:6379")
$redis = Redis.new(:host => uri.host, :port => uri.port)

AttributeCache::StorageProviders.Redis = $redis
