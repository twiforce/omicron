class AddSpamtxt < ActiveRecord::Migration
  def change
    add_column :settings_records, :spamtxt_enabled, :boolean, default: false
  end
end
