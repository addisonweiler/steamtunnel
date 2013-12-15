class AddFacebookBoolToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :facebook, :boolean, :default => false
  end
end
