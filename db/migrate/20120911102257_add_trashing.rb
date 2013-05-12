class AddTrashing < ActiveRecord::Migration
  def change
    add_column :settings_records, :new_threads_to_trash, :boolean, default: false
  end
end
