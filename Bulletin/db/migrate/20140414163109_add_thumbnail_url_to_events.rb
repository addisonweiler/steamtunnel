class AddThumbnailUrlToEvents < ActiveRecord::Migration
  def change
    add_column :events, :thumbnail_url, :string
  end
end
