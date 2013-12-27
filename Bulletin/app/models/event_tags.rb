class EventTags < ActiveRecord::Base
  belongs_to :event

  validates :tag_id, :presence => true
  validates :event_id, :presence => true
end
