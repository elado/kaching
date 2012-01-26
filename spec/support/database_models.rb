class Article < ActiveRecord::Base
  belongs_to :user
end

class Follow < ActiveRecord::Base
  belongs_to :user
  belongs_to :item, polymorphic: true
end

class Car < ActiveRecord::Base
  belongs_to :driver, class_name: 'User', foreign_key: 'driver_id'
end

class Movie < ActiveRecord::Base
end

class Like < ActiveRecord::Base
  belongs_to :user
  belongs_to :item, polymorphic: true
end

class UserMovie < ActiveRecord::Base
  belongs_to :user
  belongs_to :movie
end

class User < ActiveRecord::Base
  has_many :articles

  cache_counter :articles
  
  has_many :cars, foreign_key: 'driver_id'
  
  cache_counter :following_users, class_name: 'Follow' do |user|
    Follow.where(user_id: user.id, item_type: 'User').count
  end
  
  cache_counter :follower_users, class_name: 'Follow', foreign_key: 'item_id' do |user|
    Follow.where(item_id: user.id, item_type: 'User').count
  end
  
  cache_counter :cars
  
  has_many :likes
  has_many :user_movies
  has_many :movies, through: :user_movies
  
  cache_list :likes,  polymorphic: true,
                      item_key: 'item',
                      add_method_name:    'like!',
                      remove_method_name: 'unlike!',
                      exists_method_name: 'likes?'
                      
  cache_list :user_movies, item_key: 'movie'
  # cache_list :movies
end
