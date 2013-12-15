class AddIndices < ActiveRecord::Migration
  def change
    add_index :favorites_users, :event_id
    add_index :favorites_users, :user_id
    add_index :groups_users, :group_id
    add_index :groups_users, :user_id
    add_index :selections_users, :group_id
    add_index :selections_users, :user_id
    add_index :groups_tags, :group_id
    add_index :groups_tags, :tag_id
  end
end
