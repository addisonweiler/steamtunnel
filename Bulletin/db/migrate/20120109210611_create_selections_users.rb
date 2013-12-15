class CreateSelectionsUsers < ActiveRecord::Migration
  def change
    create_table :selections_users, :id => false do |t|
      t.integer :group_id
      t.integer :user_id
    end
  end
end
