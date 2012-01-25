class CreateCars < ActiveRecord::Migration
  def change
    create_table :cars do |t|
      t.integer :driver_id
      t.string :model
    end
  end
end
