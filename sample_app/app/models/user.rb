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
end
