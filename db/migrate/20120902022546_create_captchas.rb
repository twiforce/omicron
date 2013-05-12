class CreateCaptchas < ActiveRecord::Migration
  def change
    create_table :captchas do |t|
      t.string    :word
      t.integer   :key
      t.timestamps
    end

    add_index :captchas, :key,          unique: true
    add_index :captchas, :word,         unique: true
  end
end
