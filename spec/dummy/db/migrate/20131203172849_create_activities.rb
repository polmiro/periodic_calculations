class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.integer :quantity, :default => 0, :null => false
      t.timestamps
    end
  end
end
