class CreateSettingsRecords < ActiveRecord::Migration
  def change
    create_table :settings_records do |t|
      t.text      :allowed_file_types
      t.integer   :max_file_size,           default: 3.megabytes    # bytes
      t.integer   :threads_per_page,        default: 10         # threads
      t.integer   :max_threads,             default: 1000       # threads
      t.integer   :bump_limit,              default: 500        # posts
      t.integer   :thread_posting_speed,    default: 15         # seconds
      t.integer   :reply_posting_speed,     default: 5          # seconds
      t.integer   :max_references_per_post, default: 10         # references
      t.timestamps
    end
  end
end
