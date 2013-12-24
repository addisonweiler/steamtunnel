# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or find_or_create_by_named alongside the db with db:setup).
#
# Examples:
#
#   cities = City.find_or_create_by_name([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.find_or_create_by_name(:name => 'Emanuel', :city => cities.first)

# Groups for sites scraped
stanford_events = Group.find_or_create_by_name(:name => "Stanford Events", :source => "http://events.stanford.edu")
stanford_events.thumbnail = "StanfordEvents.png"
stanford_events.save
lectures = Tag.find_or_create_by_name(:name => "Lectures")
stanford_events.tags << lectures if !stanford_events.tags.include?(lectures)

lively_arts = Group.find_or_create_by_name(:name => "Lively Arts",
 :source => "http://livelyarts.stanford.edu/month_list.php?filter=all")
lively_arts.thumbnail = "LivelyArts.png"
lively_arts.save
performances = Tag.find_or_create_by_name(:name => "Performances")
lively_arts.tags << performances if !lively_arts.tags.include?(performances)

career = Tag.find_or_create_by_name(:name => "Career")
bases = Group.find_or_create_by_name(:name => "BASES", :source => "http://bases.stanford.edu/events/")
bases.thumbnail = "BASES.png"
bases.save
cdc = Group.find_or_create_by_name(:name => "CDC", 
:source => "https://stanford-csm.symplicity.com/calendar/index.php?ss=ical_agenda&_ksl=1&s=")
cdc.thumbnail = "CDC.png"
cdc.save
bases.tags << career if !bases.tags.include?(career)
cdc.tags << career if !cdc.tags.include?(career)

politics = Tag.find_or_create_by_name(:name => "Politics")
sig = Group.find_or_create_by_name(:name => "SIG",
 :source => "http://www.stanford.edu/group/SIG/cgi-bin/index.php/events")
sig.thumbnail = "SIG.png"
sig.save
sig.tags << politics if !sig.tags.include?(politics)

tech = Tag.find_or_create_by_name(:name => "Tech")
acm = Group.find_or_create_by_name(:name => "ACM", :source => "http://stanfordacm.com/")
acm.thumbnail = "ACM.png"
acm.save
acm.tags << tech if !acm.tags.include?(tech)

parties = Tag.find_or_create_by_name(:name => "Parties")
general = Group.find_or_create_by_name(:name => "General")
general.thumbnail = "General.png"
general.save
general.tags << parties if !general.tags.include?(parties)

friends = Group.find_or_create_by_name(:name => "Friends") # Active for everybody
friends.thumbnail = "Facebook.png"
friends.save
Group.find_or_create_by_name(:name => "Officer Data") # Data holder

# Tags
Tag.find_or_create_by_name(:name => "Sports")
Tag.find_or_create_by_name(:name => "New", :visible => false)
Tag.find_or_create_by_name(:name => "Facebook", :visible => false)
#Tag.find_or_create_by_name(:name => "User-Created", :visible => true)
