# attribute_cache

Cache attributes of Rails ActiveRecord in an external storage such as Redis.

## Installation

	gem 'attribute_cache', git: 'git://github.com/elado/attribute_cache.git'

Requires Ruby 1.9.2+.

## Storage options

### Redis

	# config/initializers/redis.rb
	$redis = Redis.new

	AttributeCache::StorageProviders.Redis = $redis

## cache_counter

Cache counts of associations.

Adds a count method to a class, and adds an after_commit callback to the countable class.

### Usage

	# article.rb
	class Article < ActiveRecord::Base
	  belongs_to :user
	end

	# user.rb
	class User < ActiveRecord::Base
	  has_many :articles

	  cache_counter :articles
	end
	
	# code
	user = User.create!
	
	user.article_count # => 0

	user.articles << Article.new

	user.article_count # => 1
	

`cache_counter` adds an after_commit to increase/decrease the counter directly on the data store.


#### More Options

Specify a `class_name` and provide a block to return a count for custom operations:

	class User < ActiveRecord::Base
	  cache_counter :following_users, class_name: 'Follow' do |user|
	    Follow.where(user_id: user.id, item_type: 'User').count
	  end

	  cache_counter :follower_users, class_name: 'Follow', foreign_key: 'item_id' do |user|
	    Follow.where(item_id: user.id, item_type: 'User').count
	  end
	end


## cache_list

Caches presence of items in a list that is belong to antoer item. Automatically adds `cache_counter` on that association.

Example: User can Like stuff. In order to check if a user likes an item, you can run a query like

	Like.where(user_id: user.id, item_id: item.id, item_type: item.class.name).exists?
	
But with many items and checkes, this process might take some time.

In order to solve that, `attribute_cache` fetches once all liked items and stores them in cache.

`cache_list :likes` generates these methods:

	add_like!(item)
	remove_unlike!(item)
	has_likes(item)              
	likes_count              
	reset_cache_likes!

 and from now on you can ask if `user.likes?(item)`

	# like.rb
	class Like < ActiveRecord::Base
	  belongs_to :user
	  belongs_to :user, polymorphic: true
	end

	# movie.rb
	class Movie < ActiveRecord::Base
	end

	# user.rb
	class User < ActiveRecord::Base
	  has_many :likes

	  cache_list :likes
	end

	# code
	user = User.create!
	
	memento = Movie.create!(name: "memento")
	inception = Movie.create!(name: "inception")
	
	user.add_like!(memento)      # like! is an auto generated method!
	
	user.likes_count             # => 1
	
	user.has_like?(memento)      # => true
	user.has_like?(inception)    # => false
	
	user.add_like!(inception)
	user.has_like?(inception)    # => true
	
	user.likes_count             # => 2
	
	user.remove_like(inception)
	user.has_like?(inception)    # => false
	
	user.likes_count             # => 1
	
The first time `has_like?` is hit, it collects all IDs of likes items and stores them in cache.

The second time just asks the cache, and every creation/deletion of an item updates the cache.


### Options


	item_key					The item name on the list table (like 'movie' for 'movie_id')
	polymorphic					Whether list table is polymorphic (list table contains 'item_id' and 'item_type')
	add_method_name				Name of method to add. Can be customized, for example 'like!' instead of 'add_like!'
	remove_method_name			Name of method to remove. Can be customized, for example 'unlike!' instead of 'removes_like!'
	exists_method_name			Name of method to check if exists. Can be customized, for example 'likes?' instead of 'has_like?'
	reset_cache_method_name		Reset cache, after manual insertion
	class_name					Name of class of list table, in case it's different than default
