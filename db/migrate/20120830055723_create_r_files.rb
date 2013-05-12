class CreateRFiles < ActiveRecord::Migration
  def change
    create_table :r_files do |t|
      t.string    :filename
      t.string    :md5_hash
      t.string    :extension
      t.integer   :size
      t.integer   :uploads_count, default: 0
      t.integer   :columns
      t.integer   :rows
      t.boolean   :resized,       default: false
      t.timestamps
    end
  end
end
