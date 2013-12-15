class AddFbiDtoUser < ActiveRecord::Migration
  def up
    add_column :users, :fb_id, :bigint
  end

  def down
    remove_column :users, :fb_id
  end
end
