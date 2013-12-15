class AddVisibleToTags < ActiveRecord::Migration
  def change
    add_column :tags, :visible, :boolean, :default => true
  end
end
