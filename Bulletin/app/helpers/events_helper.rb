module EventsHelper
  # Select generalized ID for event
  def generalized_event_id(event, friendEvents, generalEvents, friendID, generalID)
    if friendEvents.include?(event)
      return friendID
    elsif generalEvents.include?(event)
      return generalID
    else
      return event.group_id
    end
  end
  # Select generalized name for event
  def generalized_event_name(event, friendEvents, generalEvents, friendID, generalID, groupNames)
    # TODO IMPORTANT this causes the cache hits to groups
    if friendEvents.include?(event)
      return "Friends (#{groupNames[event.group_id]})"
    elsif generalEvents.include?(event)
      return "General (#{groupNames[event.group_id]})"
    else
      return groupNames[event.group_id]
    end
  end
  # TODO generalize this
  def generalized_event_thumbnail(event, friendEvents, generalEvents, friendID, generalID)
    # TODO IMPORTANT this causes the cache hits to groups
    if friendEvents.include?(event)
      return image_tag "thumbnails/#{Group.find(friendID).thumbnail}", :class => "thumbnail"
    elsif generalEvents.include?(event)
      return image_tag "thumbnails/#{Group.find(generalID).thumbnail}", :class => "thumbnail"
    else
      thumbnail = event.group.thumbnail
      if thumbnail.nil?
        return nil
      else
        return image_tag "thumbnails/#{thumbnail}", :class => "thumbnail"
      end
    end
  end
end
