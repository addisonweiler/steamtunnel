class CreateEventTags < ActiveRecord::Migration
  def up
    create_table :event_tags do |t|
      t.integer :event_id
      t.integer :tag_id
      t.string :tag_name
    end
  end

  def down
    drop_table :event_tags
  end
end
