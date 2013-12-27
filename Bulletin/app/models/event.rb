class Event < ActiveRecord::Base
	belongs_to :group
  has_many :event_tags

  # Indexing for the ThinkingSphinx search engine
  define_index do
    indexes name
    indexes description
    indexes location
    has start, finish
  end

  # Validates that event is unique
  validates :name, :uniqueness => {:scope => :start, 
    :message => "has already been taken for the chosen start time"}
  validates :name, :location, :presence => true

	# Add user Facebook events using rest API
	def self.pollUser(user, group)
	    @rest = Koala::Facebook::API.new(user.fb_token)
      events = @rest.rest_call("events.get")     
	    events.each do |e|
	      if !e["eid"].nil? and !self.find_by_fb_id(e["eid"])
          # TODO how get permalink for FB events?
	        self.create(:name => e["name"], :start => Time.at(e["start_time"]),
	                     :finish => Time.at(e["end_time"]), :location => e["location"],
	                     :fb_id => e["eid"], :description => e["description"], 
                       :group_id => group.id)
	      end
	    end
  end

  # Convert time string in PST to UTC Time object
  def self.PSTtoUTC(time_str)
    return nil if time_str.nil? 
    Time.zone = 'Pacific Time (US & Canada)'
    pst = Time.zone.parse(time_str)
    if pst.hour == 0 # Probably no hour given
      pst = Time.zone.parse(pst.strftime("%Y-%m-%d 12:%M:%S %z"))
    end
    Time.zone = 'UTC'
    return Time.zone.parse(pst.to_s)
  end
  
  def self.increment_day(time, increment)
    day_after = Time.parse((time + increment).strftime('%Y-%m-%d 0:00:00'))
    return day_after
  end

  # Dates for date selector, and read date param
  def self.manage_dates
    start = Time.now
    finish = increment_day(start, 24*60*60)
    @dates = {"Today" => [increment_day(start, 0).utc.strftime('%Y-%m-%d %H:%M:%S UTC'), 
      finish.utc.strftime('%Y-%m-%d %H:%M:%S UTC')]}
    6.times do |i|
      i += 1
      day = (Time.now + 24*60*60*i)
      day_of_week = day.strftime('%A')
      @dates[day_of_week] = [increment_day(day, 0).utc.strftime('%Y-%m-%d %H:%M:%S UTC'), 
        increment_day(day, 24*60*60).utc.strftime('%Y-%m-%d %H:%M:%S UTC')]
    end
    @dates["This Week"] = [start.utc.strftime('%Y-%m-%d %H:%M:%S UTC'), 
      increment_day(start, 24*60*60*7).utc.strftime('%Y-%m-%d %H:%M:%S UTC')]
    next_month = (start.strftime('%m').to_i + 1) % 12
    next_date = Time.parse(start.strftime("%Y-#{next_month}-01 00:00:00"))
    @dates["This Month"] = [start.strftime('%Y-%m-%d %H:%M:%S UTC'), 
      next_date.utc.strftime('%Y-%m-%d %H:%M:%S UTC')]
    return @dates
  end

  def self.find_by_params(params)
    #TODO: Implement this
  end
end
