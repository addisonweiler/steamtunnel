class AddFbiDtoEvents < ActiveRecord::Migration
  def up
  	add_column :events, :fb_id, :int
  end

  def down
  	remove_column :events, :fb_id
  end
end
