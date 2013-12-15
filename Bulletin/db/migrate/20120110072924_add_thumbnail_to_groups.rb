class AddThumbnailToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :thumbnail, :string
  end
end
