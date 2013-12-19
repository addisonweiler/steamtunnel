class ChangePostgresStringToText < ActiveRecord::Migration
  def up
    change_column :events, :name, :text
  end

  def down
    change_column :events, :name, :string
  end
end
