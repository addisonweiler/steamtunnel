require 'open-uri'
require 'time'
require 'htmlentities'
require 'nokogiri'
require 'mechanize'
require 'open-uri'
require 'watir-webdriver'
#require 'ruby-debug'
#require 'passwords' Disable for heroku

# Save a email to group id hash of officers in Officer Data :data
task :hash_officers => :environment do
  officerHash = {}
  f = File.open("emails", 'r')
  groups = Marshal.load(f)
  groups.each_pair do |group, officers|
    puts group
    parentOrg = Group.create(:name => group)
    officers.each_pair do |position, info|
      if !position.include?("Advisor") and info[:email] != "Unknown"
        if officerHash.has_key?(info[:email])
          officerHash[info[:email]] << parentOrg.id
        else
          officerHash[info[:email]] = [parentOrg.id]
        end
      end
    end
  end
  officerData = Group.find_by_name("Officer Data")
  officerData.data = officerHash
  officerData.save
end

# Create users for each officer scraped from orgsync
task :add_officers => :environment do
  f = File.open("emails", 'r')
  groups = Marshal.load(f)
  groups.each_pair do |group, officers|
    puts group
    parentOrg = Group.create(:name => group)
    officers.each_pair do |position, info|
      if !position.include?("Advisor") and info[:email] != "Unknown"
        off = User.find_or_create_by_email(info[:email])
        off.attributes = {:password => "password", :password_confirmation => "password"}
        off.confirmed_at = Time.now
        off.save
        parentOrg.users << off
      end
    end
  end
end

# Cross Reference Stanford Who
task :stanford_who => :environment do
  f = File.open("orgsyncTotal", 'r')
  groups = Marshal.load(f)
  f.close
  # Cross reference with stanford who
  agent = Mechanize.new
  newGroups = {}
  validated = false
  #stats
  nameCount = 0
  emailCount = 0
  groups.each_pair do |group, officers|
    newOfficers = {}
    officers.each_pair do |position, name|
      #name.downcase!
      #arr = name.split(" ")
      #arr.each do |v|
      #  v.capitalize!
      #end
      #name = arr.join(" ")
      url = "https://stanfordwho.stanford.edu/SWApp/authDetail.do?search=#{URI.escape(name)}&affilfilter=everyone&soundex=&stanfordonly=checkbox&filters=&key=DR666K571&list=false"
      page = agent.get(url)
      # Navigate login
      if !validated
        form = agent.page.forms.first
        form.username = Passwords::Stanford_login[:username]
        form.password = Passwords::Stanford_login[:password]
        formPage = form.submit
        form = formPage.forms.first
        results = form.submit
        validated = true
      else
        results = agent.page.forms.first.submit
      end
      nameCount += 1

      email = "Unknown"
      # Sunnet ID
      idSearch = results.search("dd.stanford").search("li")
      emailSearch = results.search("a").select {|e| e.text =~ /@stanford.edu/}
      if !emailSearch.empty?
        email = emailSearch[0].text
        emailCount += 1
      elsif !idSearch.empty?
        id = idSearch[0].text
        email = id + "@stanford.edu"
        emailCount += 1
      end
      email.strip!

      puts name
      puts email
      newOfficers[position] = {:name => name, :email => email}
    end
    newGroups[group] = newOfficers
  end
  f = File.open('emails', 'w')
  Marshal.dump(newGroups, f)
  f.close
  puts newGroups
  puts "#{nameCount} Names, #{emailCount} emails found"
end

# There should be a builtin for this
def mergeHashes(hash1, hash2)
  hash2.each_pair do |key, value|
    hash1[key] = value
  end
  return hash1
end

# Scrape student groups from OrgSync and names of officers
task :scrape_orgsync, :page do |t, args|
  page = args[:page].to_i
  browser = Watir::Browser.new
  browser.window.resize_to(1400, 800)
  browser.goto "orgsync.stanford.edu"
  browser.text_field(:name => "username").set(Passwords::Stanford_login[:username])
  browser.text_field(:name => "password").set(Passwords::Stanford_login[:password])
  browser.form(:name => "login").submit
  #Orgsync
  browser.a(:text => "Browse Organizations").click
  groups = {}
  groupsUrl = browser.url
  sleep 3
  browser.link(:text, "32").click
  pageDiff = 32 - page
  pageDiff.times do |i|# Skip forward to correct page
    puts i+1
    sleep 3
    browser.link(:text, /Prev/).click
  end
  # page 17, fml
  #sleep 3
  #browser.link(:text, "17").click

  #browser.link(:text, page).click # Go to letter of alphabet
  sleep 2
  linkObjs = browser.as(:class => "profile-image-link")
  linkCount = linkObjs.length
  # Urls from links
  links = []
  linkCount.times do |ind|
    links << browser.link(:class => "profile-image-link", :index => ind).href
  end
  # Visit each group link and scrape the names
  linkCount.times do |ind|
    browser.goto(links[ind])
    sleep 2
    browser.a(:onclick, /display_profile/).click
    sleep 2
    title = browser.h1(:class => "org-title").text
    groups[title] = {}
    divs = browser.divs(:class => "extra-items")
    # Get name of every person affiliated with group
    divs.each do |d|
      if d.text.include?("Name")
        info = d.text.split("\n")
        groups[title][info[0]] = info[1]
      end
    end
  end

  print groups
  f = File.open("orgsync"+page.to_s, 'w')
  Marshal.dump(groups, f)
  f.close
end

task :scrape_orgsync_mechanize do 
  agent = Mechanize.new { |a| a.user_agent_alias = "Windows IE 6" }
  page = agent.get("http://orgsync.stanford.edu") #"https://orgsync.com/welcome/list_organizations?school_id=521")
  form = agent.page.forms.first
  form.username = "stevend2"
  form.password = 
  formPage = form.submit
  form = formPage.forms.first
  orgPage = form.submit
  browseOrgs = orgPage.link_with(:text => "Browse Organizations").click
  debugger
  print "Test"
end

task :gross_merging => :environment do
  orgGroups = {}
  f = File.open("orgsync1", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync12", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync15", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync19", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync21", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync24", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync27", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync3", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync32", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync6", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync9", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync10", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync13", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close 
  f = File.open("orgsync17", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync2", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync22", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync25", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync28", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync30", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync4", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync7", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsyncP", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync11", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync14", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync18", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync20", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync23", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync26", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync29", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync31", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync5", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsync8", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close
  f = File.open("orgsyncQ", 'r')
  groups = Marshal.load(f)
  orgGroups = mergeHashes(orgGroups, groups)
  f.close

  f = File.open("orgsyncTotal", 'w')
  Marshal.dump(orgGroups, f)
  f.close
end