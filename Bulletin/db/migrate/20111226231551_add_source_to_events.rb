class AddSourceToEvents < ActiveRecord::Migration
  def change
    add_column :groups, :source, :string
  end
end
