class AddFavs < ActiveRecord::Migration
  def change
    add_column :users, :seen, :text
    add_column :users, :favorites, :text
  end
end
