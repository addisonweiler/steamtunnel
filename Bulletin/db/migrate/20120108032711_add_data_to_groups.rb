class AddDataToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :data, :text
  end
end
