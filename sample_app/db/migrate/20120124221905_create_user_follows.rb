class CreateUserFollows < ActiveRecord::Migration
  def change
    create_table :user_follows do |t|
      t.references :user
      t.references :item, polymorphic: true
    end
  end
end
