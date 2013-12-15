class ChangeFbIdinEvents < ActiveRecord::Migration
  def change
    change_column :events, :fb_id, :bigint 
  end
end
