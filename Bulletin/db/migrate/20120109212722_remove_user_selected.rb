class RemoveUserSelected < ActiveRecord::Migration
  def change
    remove_column :users, :selection
  end
end
