class AddVideoInfo < ActiveRecord::Migration
  def change
    add_column :r_files, :video_title, :string
    add_column :r_files, :video_duration, :integer
  end
end
