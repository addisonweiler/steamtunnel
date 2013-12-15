class AddPersonalToUsers < ActiveRecord::Migration
  def change
    add_column :groups, :personal, :boolean, :default => false
  end
end
