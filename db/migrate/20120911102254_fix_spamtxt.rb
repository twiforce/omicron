class FixSpamtxt < ActiveRecord::Migration
  def change
    add_column :settings_records, :spamtxt, :text
  end
end
