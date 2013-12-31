require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'time'
require 'htmlentities'
require 'nokogiri'
require 'mechanize'
require 'open-uri'
#require 'ruby-debug'

# Collection of scrapes
task :scrape_all => :environment do
  Rake::Task['scrape_lively_arts'].invoke
  Rake::Task['scrape_sports'].invoke
  Rake::Task['scrape_events'].invoke
  Rake::Task['scrape_dept_groups'].invoke
  Rake::Task['scrape_student_groups'].invoke
  Rake::Task['cleanup_event_unicode'].invoke

  #Rake::Task['scrape_bases'].invoke #TODO: No events created from this
  #Rake::Task["scrape_sig"].invoke #sig hasn't posted events in awhile, not updating scraper until they start
  #Rake::Task["scrape_acm"].invoke #TODO: Find alternative, website no longer updated
  #Rake::Task["scrape_cdc"].invoke #Empty calendar, events @ http://studentaffairs.stanford.edu/cdc/services/career-fair-schedule#wincf
end

# Screen scrape lively arts with mechanize
task :scrape_lively_arts => :environment do
  @group = Group.find_by_name("Lively Arts")
  agent = Mechanize.new
  puts 'group source: ' + @group.source
  page = agent.get(@group.source)
  links = page.links_with(:text => "", :href => %r{/calendar/}) #select links that lead to a url that contains '/calendar/'
  links.each do |l|
    infopage = l.click
    @permalink = infopage.uri.to_s
    @title = infopage.at('div.page-header').text.strip
    puts @title
    @time = infopage.at('div.span4').at('div.performances').at('h3').text
    @location = infopage.at('div.span4').at('div.performances').at('div.location').text
    infopage.at('div.span4').at('div.block').at('div.block').css('br').each{ |br| br.replace "\n" }
    pricing = infopage.at('div.span4').at('div.block').at('div.block').text.strip
    paragraphs = infopage.search('div.span8').search('div.field').search("p")
    textArr = []
    textArr << pricing
    paragraphs.each do |p|
      if p.attributes["class"].nil? or not p.attributes["class"].value.include? "relevent"
        textArr << p.text
      end
    end
    @description = ""
    textArr.each do |text|
      @description += text
      @description += "\n"
    end
    @description.strip!
    @description.gsub!("\r\n", " ")
    # Add spaces after periods with no space
    @description.gsub!(/\.(\w)/, '\1')
    Event.create(:name => @title, :description => @description, :location => @location,
                 :start => Event.PSTtoUTC(@time), :group_id => @group.id, :permalink => @permalink)
  end
end

# Scrape CDC
task :scrape_cdc => :environment do
  group = Group.find_by_name("CDC")
  url = "https://stanford-csm.symplicity.com/utils/handleDynamicCalendarRequests.php?" \
  "csp_subsystem=calendar&ret_tab=&request_type=get_events&timeshift=480&from=20120104&to=20130105"
  file_handle = open(url)
  parsed_json = ActiveSupport::JSON.decode(file_handle)
  coder = HTMLEntities.new
  parsed_json.each do |event|
    puts event
    event["text"] = coder.decode(event["text"])
    event["text"].gsub!(/<.?b>/, '')
    event["text"] += "<br>"
    info = event["text"].scan(/(.*?)<br>/)
    if info.length == 3
      @title = info[0][0].strip
      @description = info[1][0].strip
      if @title == "Employer Information Session"
        @title += @description.scan(/(: .*)/)[0][0]
      end
      @location = info[2][0].strip
    elsif info.length == 2
      @title = info[0][0].strip
      @location = info[1][0].strip
    else
      @title = info[0][0].strip
    end
    event = Event.create(:name => @title, :description => @description, :location => @location,
     :start => Event.PSTtoUTC(event["start_date"]), :finish => Event.PSTtoUTC(event["end_date"]),
     :group_id => group.id, :permalink => group.source)
    tagEvent(event, group)
  end
end

# Scrape groups from http://events.stanford.edu/byOrganization/departmentalOrganizationList.shtml
task :scrape_dept_groups => :environment do
  group = Group.find_by_name("Stanford Events")
  scrape_groups("http://events.stanford.edu/byOrganization/departmentalOrganizationList.shtml",
  group)
end

# Helper for scrape dept groups and scrape student groups
def scrape_groups(url, group=nil)
  agent = Mechanize.new
  page = agent.get(url)
  links = agent.page.links.select {|l| l.href.include? "byOrganization"} # pairs of Title/RSS links
  # Check for Dep't homepage
  content = page.search("#content_main").search("p")
  content.each_with_index do |dept, ind|
    ind += 1
    homepage = nil
    homelink = dept.search("a")[-1]
    if homelink.previous.text.include? "Homepage"
      homepage = homelink.text
    end
    puts links[2*ind]
    source = links[2*ind + 1].click.uri.to_s
    # TODO don't want to many groups, so just save these as Stanford Events
    if group.nil?
      group = Group.new(:name => links[2*ind].text, :source => source, :homepage => homepage)
    end
    #if !group.save
    #  group = Group.find_by_name(links[2*ind].text)
    #end
    scrape_event_feed(source, group)
  end
  
end

# Scrape student groups and events from http://events.stanford.edu/byOrganization/studentOrganizationList.shtml
task :scrape_student_groups => :environment do
  scrape_groups("http://events.stanford.edu/byOrganization/studentOrganizationList.shtml")
end


# Scrape RSS feed at events.stanford.edu
task :scrape_events => :environment do
  group = Group.find_by_name("Stanford Events")
  performances = Group.find_by_name("Lively Arts")
  # By Category
  scrape_event_feed("http://events.stanford.edu/xml/rss.xml", group) # Featured
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/2/rss.xml", group) # Lectures
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/3/rss.xml", group) # Conferences
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/4/rss.xml", performances) # Performance
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/7/rss.xml", group) # Exhibition
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/19/rss.xml", group) # Classes
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/12/rss.xml", group) # Meeting
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/15/rss.xml", group) # Tour
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/10/rss.xml", group) # Recreational Sports
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/13/rss.xml", group) # Religious
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/14/rss.xml", group) # Social
  # By Subject
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/0/rss.xml", group) # All Arts
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/9/rss.xml", performances) # Music
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/6/rss.xml", performances) # Drama/Theater
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/5/rss.xml", performances) # Dance
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/20/rss.xml", group) # Visual Arts
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/8/rss.xml", performances) # Film
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/11/rss.xml", group) # Public Service
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/18/rss.xml", group) # International
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/21/rss.xml", group) # Environment
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/22/rss.xml", group) # Engineering
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/23/rss.xml", group) # Humanities

  scrape_event_feed("http://events.stanford.edu/xml/byCategory/24/rss.xml", group) # Health/Wellness
  #scrape_event_feed("http://events.stanford.edu/xml/byCategory/17/rss.xml", group) # PHD Orals
  scrape_event_feed("http://events.stanford.edu/xml/byCategory/1/rss.xml", group) # University Events
end

def scrape_event_feed(source, group)
  puts source
  content = "" # raw content of rss feed will be loaded here
  open(source) do |s| content = s.read end
  rss = RSS::Parser.parse(content, false)
  coder = HTMLEntities.new
  rss.items.each do |item|
    title = coder.decode(item.title)
    puts title
    description = coder.decode(item.description)
    data = description.split("<br/>")
    date = data[0].strip
    date = date.scan(/Date:(.*)/i)[0][0]
    location = data[1].strip
    location.gsub!("\n", ", ")
    location = location.scan(/Location:(.*)/i)[0][0]
    # Remove <br/>'s caught in location, and remove newlines
    description = ""
    data.each_with_index do |text, ind|
      if ind >= 2
        description += text
      end
    end
    description.gsub!(/\r\n/, "\n")
    description.strip!
    event = Event.create(:name => title, :description => description, :location => location,
     :start => Event.PSTtoUTC(date), :group_id => group.id, :permalink => item.link)
    tagEvent(event, group)
  end
end

# Screen scrape http://bases.stanford.edu/events/ with mechanize
# TODO location and specific time, if possible given unstandardized formatting
task :scrape_bases => :environment do
  @group = Group.find_by_name("BASES")
=begin TODO fix this
  agent = Mechanize.new
  page = agent.get(@group.source)
  # Upcoming events
  div = page.search(".box.padded.clearfix")
  @dates = div.search(".entry-meta")
  @titles = div.search(".entry-title")
  num_events = @dates.count
  debugger
  num_events.times do |i|
    puts @titles[i]
    description = @titles[i].next.text
    description.strip!
    date = @dates[i].text + " 12 pm" # default
    # Follow link to get url
    link = agent.page.links.select {|l| l.text == @titles[i].text }[0]
    debugger
    event_page = link.click
    permalink = event_page.uri.to_s
    Event.create(:name => @titles[i].text, :start => Event.PSTtoUTC(date), :description => description, 
      :permalink => permalink,  :group_id => @group.id)
  end
=end
  scrape_event_feed("http://events.stanford.edu/xml/byOrganization/182/rss.xml", @group)
end

# Scrape top sports events, create a group for each sport RSS http://www.gostanford.com/rss/rss-index.html
task :scrape_sports => :environment do
  #source = "http://www.gostanford.com/main/Schedule.dbml"
  source = "http://www.gostanford.com/rss.dbml?db_oem_id=30600&media=schedules" # url or local file

  content = "" # raw content of rss feed will be loaded here
  open(source) do |s| content = s.read end
  rss = RSS::Parser.parse(content, false)
  coder = HTMLEntities.new
  rss.items.each do |item|
    puts 'item: ' + item.to_s
    title = item.title.split('(')[0]
    puts title
    sport = title.split(":")[0]
    pubdate = item.title.split('(')[1].split(')')[0]
    time = item.pubDate.to_s[17, 8]
    date = Event.SportTime(pubdate + ' ' + time)
    description = item.description.split('>')[1].split('<')[0] #text between <p> delimiters
    locpart1 = description.split('-')[0]
    location = locpart1[2, (locpart1.length - 3)]
    group = Group.find_by_name_or_create(sport)
    group.source = item.link
    group.save
    # Tag the groups
    sportsTag = Tag.find_by_name("Sports")
    group.tags << sportsTag if !group.tags.include?(sportsTag)
    event = Event.create(:name => title, :description => description, :location => location,
     :start => date, :group_id => group.id, :permalink => item.link)
    tagEvent(event, group)
  end
end

# Screen scrape SIG with mechanize (http://www.stanford.edu/group/SIG/cgi-bin/index.php/events)
task :scrape_sig => :environment do
  @group = Group.find_by_name("SIG")
  source = 'http://www.stanford.edu/group/SIG/cgi-bin/wordpress/?feed=rss2'
  content = "" # raw content of rss feed will be loaded here
  open(source) do |s| content = s.read end
  rss = RSS::Parser.parse(content, false)
  coder = HTMLEntities.new
  rss.items.each do |item|
    #title = item.title.split('(')[0]
    puts item
    #sport = title.split(":")[0]
    #pubdate = item.title.split('(')[1].split(')')[0]
    #time = item.pubDate.to_s[17, 8]
    #date = Event.SportTime(pubdate + ' ' + time)
    #description = item.description.split('>')[1].split('<')[0] #text between <p> delimiters
    #group = Group.find_by_name_or_create(sport)
    #group.source = item.link
    #group.save
                                                               # Tag the groups
    #sportsTag = Tag.find_by_name("Sports")
    #group.tags << sportsTag if !group.tags.include?(sportsTag)
    #Event.create(:name => title, :description => description, :location => coder.decode(item.description),
    #             :start => date, :group_id => group.id, :permalink => item.link)
  end
  #
  #agent = Mechanize.new
  #page = agent.get(@group.source)
  #items = page.search("p.MsoNormal")
  #start = 0
  #items.each_with_index do |item, ind|
  #  if item.text.include? "This Week"
  #    start = ind
  #    break
  #  end
  #end
  ## Walk over page, finding event segments
  #curr = items[start + 1]
  #while(true) do
  #  debugger
  #  curr = increment(curr)
  #  if curr.text =~ /http/ # One event is all within a paragraph
  #    saved = curr.next
  #    curr = curr.children[0]
  #  elsif curr.text.include? "Do you want"
  #    break
  #  end
  #  title = curr.text
  #  puts title
  #  curr = increment(curr.next)
  #  date = curr.text
  #  curr = increment(curr.next)
  #  if curr.text.include? "-"
  #    times = curr.text.split("-")
  #    @start = date + " " + times[0] + times[1][-2, 2] # am/pm
  #    @finish = date + " " + times[1]
  #  else
  #    @start = date + " " + curr.text
  #    @finish = nil
  #  end
  #  curr = increment(curr.next)
  #  location = curr.text
  #  curr = increment(curr.next)
  #  description = curr.text
  #  curr = increment(curr.next)
  #  permalink = curr.text.scan(/http.*/)[0]
  #  Event.create(:name => title, :start => Event.PSTtoUTC(@start), :finish => Event.PSTtoUTC(@finish), :location => location,
  #      :description => description, :permalink => permalink, :group_id => @group.id)
  #  curr = saved || curr.next
  #  saved = nil
  #end
end

# Helper method for nokogiri/mechanize nodes
def increment(curr)
   while !curr.nil? and curr.text.strip.length <= 4 do
      curr = curr.next
    end
    return curr
end

# Screen scrape Stanford ACM http://stanfordacm.com/
# TODO better permalink?
task :scrape_acm => :environment do
      date = time.text
      if Time.parse(date) < Time.parse("Aug 31") # Set correct year
        date += " 2013 "
      end
      curr = increment(time.next).children[0]
      curr = increment(curr.next)
      @title = curr.text
      break if @title.include? "Slot is open"
      puts @title
      curr = increment(curr.next)
      if curr.text.include? "AM" or curr.text.include? "PM" # Event vs. talk
        print "\n REACHED HERE1 \n"
        data = curr.text.split("@")
        @location = data[1]
        if data[0].include? "-"
          data = data[0].split("-")
          @start = date + " " + data[0]
          @finish = date + " " + data[1]
        else
          @start = date + " " + data[0]
          @finish = nil
        end
        curr = increment(curr.next)
        @description = curr.text
      else # Talk
        print "\n REACHED HERE2 \n"
        @title += " (" + curr.text + ")"
        #curr = increment(curr.next)
        #@description = "Talk by " + @title
        @title = curr.text
        #curr = increment(curr.next)
        #@description += "\n" + curr.text if !curr.nil?
        #@location = "Gates 104"
        @start = date + " 6 PM"
        @finish = nil
      end
      event = Event.create(:name => @title, :start => Event.PSTtoUTC(@start), :finish => Event.PSTtoUTC(@finish), :location => @location,
          :description => @description, :permalink => @group.source, :group_id => @group.id)
      tagEvent(event, @group)
end

def tagEvent(event, group)
  groupTags = GroupsTags.find_by_group_id(group.id)

  if !groupTags.nil?
    tag_id = groupTags.tag_id
    tag_name = Tag.find_by_id(tag_id).name
    puts "Tag: " + tag_name
    EventTags.create(:event_id => event.id, :tag_id => tag_id, :tag_name => tag_name)
  end
end