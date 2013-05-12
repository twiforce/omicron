class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string  :hashname
      t.text    :settings
      t.timestamps
    end
  end
end
