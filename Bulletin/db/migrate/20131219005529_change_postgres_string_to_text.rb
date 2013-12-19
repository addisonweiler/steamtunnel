class ChangePostgresStringToText < ActiveRecord::Migration
  def up
    change_column :events, :name, :text
    change_column :events, :location, :text
    change_column :events, :permalink, :text
  end

  def down
    change_column :events, :name, :string
    change_column :events, :location, :string
    change_column :events, :permalink, :string
  end
end
