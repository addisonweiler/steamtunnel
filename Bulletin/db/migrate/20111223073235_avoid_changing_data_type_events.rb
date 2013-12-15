class AvoidChangingDataTypeEvents < ActiveRecord::Migration
  def up
    remove_column :events, :fb_id
    add_column :events, :fb_id, :bigint
  end

  def down
    remove_column :events, :fb_id
    add_column :events, :fb_id, :int
  end
end
