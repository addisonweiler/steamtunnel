class AddSelectionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :selection, :text
  end
end
