class AddDefenceMode < ActiveRecord::Migration
  def change
    add_column :settings_records, :defence_mode, :boolean, default: false
  end
end
