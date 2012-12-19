# kaching

[![Build Status](https://secure.travis-ci.org/elado/kaching.png)](http://travis-ci.org/elado/kaching)

Makes your DB suffer less from `COUNT(*)` queries and check for existence queries of associations, by keeping and maintaining counts and lists on Redis, for faster access.

## Quick Intro & Examples

**Q: How does it help me?**

A: The short answer -- Less DB hits. More, faster Redis hits.

### Countrs

```ruby
# hits DB
author.articles.count

# first time hits DB and caches into Redis
author.articles_count

# triggers an after_commit that increases the counter on Redis, doesn't run a count query on the DB
author.articles.create!(title: "Hello")

# no DB hit. just reads from Redis
author.articles_count
```

### Lists

```ruby
user.add_like!(memento)      # writes to DB, updates Redis
user.likes_count             # no DB hit
user.has_like?(memento)      # no DB hit   # => true
user.has_like?(inception)    # no DB hit   # => false
user.add_like!(inception)    # writes to DB, updates Redis
user.has_like?(inception)    # no DB hit   # => true
user.likes_count             # no DB hit   # => 2
user.remove_like(inception)  # deletes from DB, updates Redis
user.has_like?(inception)    # no DB hit   # => false
user.likes_count             # no DB hit   # => 1
```

## Installation

```ruby
gem 'kaching'
```

Requires Ruby 1.9.2+.

## Storage options

### Redis

```ruby
# config/initializers/redis.rb
$redis = Redis.new

Kaching::StorageProviders.Redis = $redis
```

## cache_counter

Cache counts of associations.

Adds a count method to a class, and adds an after_commit callback to the countable class.

### Usage

```ruby
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

user.articles_count # => 0

user.articles.create!(title: "Hello")

user.articles_count # => 1
```

`cache_counter` adds an after_commit to increase/decrease the counter directly on the data store.


#### More Options

Specify a `class_name` and provide a block to return a count for custom operations:

```ruby
class User < ActiveRecord::Base
  cache_counter :following_users, class_name: 'Follow' do |user|
    Follow.where(user_id: user.id, item_type: 'User').count
  end

  cache_counter :follower_users, class_name: 'Follow', foreign_key: 'item_id' do |user|
    Follow.where(item_id: user.id, item_type: 'User').count
  end
end
```

## cache_list

Caches presence of items in a list that is belong to antoer item. Automatically adds `cache_counter` on that association.

Example: User can Like stuff. In order to check if a user likes an item, you can run a query like

```ruby
Like.where(user_id: user.id, item_id: item.id, item_type: item.class.name).exists?
```

But with many items and checks, this process might take some precious time.

In order to solve that, `kaching` fetches once all liked items and stores them in cache.

`cache_list :likes` generates these methods:

```ruby
add_like!(item)
remove_like!(item)
has_like?(item)              
likes_count              
reset_list_cache_likes!
```

 and from now on you can ask if `user.has_like?(item)`

```ruby
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

user.add_like!(memento)      # add_like! is an auto generated method!

user.likes_count             # => 1

user.has_like?(memento)      # => true
user.has_like?(inception)    # => false

user.add_like!(inception)
user.has_like?(inception)    # => true

user.likes_count             # => 2

user.remove_like(inception)
user.has_like?(inception)    # => false

user.likes_count             # => 1
```

The first time `has_like?` is called, it collects all IDs of likes items and stores them in cache.

The second time just asks the cache, and every creation/deletion of an item updates the cache.


### Options


```
item_key						The item name on the list table (like 'movie' for 'movie_id')
polymorphic						Whether list table is polymorphic (list table contains 'item_id' and 'item_type')
add_method_name					Name of method to add. Can be customized, for example 'like!' instead of 'add_like!'
remove_method_name				Name of method to remove. Can be customized, for example 'unlike!' instead of 'removes_like!'
exists_method_name				Name of method to check if exists. Can be customized, for example 'likes?' instead of 'has_like?'
reset_list_cache_method_name	Reset cache, after manual insertion
class_name						Name of class of list table, in case it's different than default
```
