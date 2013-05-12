class FixSomeThings < ActiveRecord::Migration
  def change
    add_column :r_files, :thumb_columns, :integer
    add_column :r_files, :thumb_rows, :integer

    add_column :users, :hidden, :text
  end
end
