class AddHomePagetoGroups < ActiveRecord::Migration
  def change
    add_column :groups, :homepage, :string
  end
end
