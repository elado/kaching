ActiveRecord::Schema.define :version => 0 do
  create_table :users do |t|
    t.string :name
  end

  create_table :admins do |t|
    t.string :name
  end

  create_table :movies do |t|
    t.string :name
  end

  create_table :user_movies do |t|
    t.belongs_to :user
    t.belongs_to :movie
  end

  create_table :likes do |t|
    t.belongs_to :user
    t.belongs_to :item, polymorphic: true
  end

  create_table :articles do |t|
    t.string :title
    t.belongs_to :user
  end

  create_table :cars do |t|
    t.string :model
    t.belongs_to :driver
  end

  create_table :follows do |t|
    t.belongs_to :user
    t.belongs_to :item, polymorphic: true
  end
end
