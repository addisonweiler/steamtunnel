class AddGroupIDtoEvents < ActiveRecord::Migration
  def up
  	add_column :events, :group_id, :int
  end

  def down
  	remove_column :events, :group_id
  end
end
