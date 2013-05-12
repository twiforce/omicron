class AddCaptchaDefensive < ActiveRecord::Migration
  def change
    add_column :captchas, :defensive, :boolean, default: false
    add_index :captchas, :defensive, uniqe: false
  end
end
