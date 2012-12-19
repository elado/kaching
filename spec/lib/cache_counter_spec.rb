require 'spec_helper'

describe Kaching::CacheCounter do
  let(:user) { User.create }
  
  it "should create method on user" do
    user.should respond_to(:articles_count)
    user.should respond_to(:reset_count_cache_articles!)
  end
  
  it "should return up-to-date count with method" do
    user.articles_count.should == 0
    user.articles << Article.new
    user.articles_count.should == 1
    user.articles << Article.new
    user.articles_count.should == 2
  end
  
  it "should update count" do
    user.articles_count.should == 0
    user.articles << Article.new

    Kaching.cache_store.get(user.kaching_key(:articles, :count)).to_i.should == 1

    user.reset_count_cache_articles!
    
    Kaching.cache_store.get(user.kaching_key(:articles, :count)).should be_blank
    
    user.articles_count.should == user.articles_count

    Kaching.cache_store.get(user.kaching_key(:articles, :count)).to_i.should == 1
  end
  
  it "should return up-to-date count for user with items" do
    user.articles << Article.new
    user.articles << Article.new
    user.articles_count.should == 2
    
    id = user.id
    
    user = User.find(id)
    user.articles_count.should == 2
  
    user.articles << Article.new
    user.articles_count.should == 3
  end
  
  it "should fetch count where not exists yet (_count method wasn't called and inserted new record)" do
    user.articles << Article.new
    user.articles << Article.new
    user.articles_count.should == 2
    user.reset_count_cache_articles!
    
    user.articles << Article.new
    user.articles_count.should == 3
  end
  
  it "should use count blocks if passed" do
    user.following_users_count.should == 0
    Follow.create(user_id: user.id, item: User.create)
    user.following_users_count.should == 1
    Follow.create(user_id: user.id, item: User.create)
    user.following_users_count.should == 2
  end
  
  context "with blocks" do
    it "should use count blocks if passed and show up-to-date count for existing user" do
      Follow.create!(user_id: user.id, item: User.create)
      Follow.create!(user_id: user.id, item: User.create)
      user.following_users_count.should == 2
  
      id = user.id
      
      user = User.find(id)
      user.following_users_count.should == 2

      Follow.create!(user_id: user.id, item: User.create)
      user.following_users_count.should == 3
    end

    it "should use count blocks if passed, other side of association" do
      follower = User.create

      user.follower_users_count.should == 0
    
      Follow.create(user_id: follower.id, item: user)
      user.follower_users_count.should == 1
    end
  end
  
  context "custom options" do
    it "should find belongs_to by options" do
      user.cars_count.should == 0
      car = Car.create!(driver: user)
      user.cars.count.should == 1
      user.cars_count.should == 1
    end
  end
end
