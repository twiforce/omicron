class AnotherFix < ActiveRecord::Migration
  def change
    add_index :users, :hashname, unique: true
  end
end
