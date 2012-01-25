# attribute_cache

Cache attributes of Rails ActiveRecord in an external storage such as Redis.

## Installation

	gem "attribute_cache"

Requires Ruby 1.9.2+.

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
	  cache_counter :following_users, class_name: 'UserFollow' do |user|
	    UserFollow.where(user_id: user.id, item_type: 'User').count
	  end

	  cache_counter :follower_users, class_name: 'UserFollow', foreign_key: 'item_id' do |user|
	    UserFollow.where(item_id: user.id, item_type: 'User').count
	  end
	end

