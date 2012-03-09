class User < ActiveRecord::Base
  has_many :articles

  cache_counter :articles
  
  has_many :cars, foreign_key: 'driver_id'
  
  # cache_counter :following_users, class_name: 'Follow' do |user|
  #   Follow.where(user_id: user.id, item_type: 'User').count
  # end
  # 
  # cache_counter :follower_users, class_name: 'Follow', foreign_key: 'item_id' do |user|
  #   Follow.where(item_id: user.id, item_type: 'User').count
  # end

  cache_counter :cars

  has_many :likes
  has_many :user_movies
  has_many :movies, through: :user_movies
  
  cache_list :likes,  polymorphic: true,
                      item_key:    'item',
                      method_verb: 'like'

  cache_list :user_movies, item_key: 'movie'
  
  has_many :following_users, class_name: 'Follow', foreign_key: 'user_id', conditions: "item_type = 'User'"
  has_many :follower_users, class_name: 'Follow', foreign_key: 'item_id', conditions: "item_type = 'User'"
  
  cache_list :following_users, class_name: 'Follow',
                               item_key: 'item',
                               method_verb: 'follow'
  
  cache_list :follower_users, class_name: 'Follow',
                              foreign_key: 'item_id',    
                              add_alter_methods: false
end
