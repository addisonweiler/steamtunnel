class EventsController < ApplicationController
  layout 'events'
  #before_filter :authenticate_user!, :only => [:index]
  before_filter :get_memberships, :only => [:new, :create]
  before_filter :initialize_selection, :only => [:index, :search]
  before_filter :manage_groups, :only => [:index, :show_favorites, :search] # only display selected group
  before_filter :manage_selections, :only => [:index, :search]
  before_filter :manage_social, :only => [:index, :show_favorites]
  before_filter :initialize_date, :only => [:index, :search]
  before_filter :initialize_tag_selection, :only => [:index, :search]

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  ### HELPERS
  # Refactored out of index for show_favorites
  def manage_groups
    # Used in view
    @friendID = Group.find_by_name("Friends").id
    @generalID = Group.find_by_name("General").id

    @allGroups = Group.all
    @groups = Group.where(:personal => false).order("name ASC").all
    @generalEvents = Event.joins(:group).where("groups.personal")
    # Hash precomputed to avoid model call in view
    @groupNames = Hash[@allGroups.collect {|g| [g.id, g.name] }]
  end

  def manage_social
    # Generalize individual events into FB Friends and General
    return true unless current_user
    friendNames = [current_user.name]
    friendNames += current_user.friends if !current_user.friends.nil?
    @friendEvents = @generalEvents.joins(:group).where("groups.name in (?)", friendNames)
  end

  def manage_selections
    # Selected groups drawn from user.selected (set initially in profile page)
    @selected_groups = Group.all
    return true unless current_user
    @selected_groups = current_user.selections
    @selected_groups_ids = @selected_groups.collect {|g| g.id}
  end

  def get_memberships
    @memberships = current_user.groups.where(:facebook => false)
  end

  def initialize_selection
    return true unless current_user
    if current_user.selections.empty? # TODO make introduced bool column for this?
      redirect_to interests_events_path
    end
  end

  # Dates for date selector, and read date param
  def initialize_date
    @dates = Event.manage_dates
    # Initialize date
    if params.has_key?("date")
      @date_changed = true
      session["date"] = params["date"]
      @selected_date = params["date"]
    else
      @date_changed = false
      @selected_date = session["date"] || 'This Week'
    end
    puts @selected_date
  end

  def initialize_tag_selection
    @tags = Tag.where(:visible => true).order("name ASC").all
    tag_ids = @tags.collect {|t| t.id}
    @selected_filters =  tag_ids.collect {|t| t.to_s}
    if params.has_key?("selected_filters")
      @tags = Tag.where(:visible => true).order("name ASC").all.select {|t| params[t.name]}
      tag_ids = @tags.collect {|t| t.id}
      @filters_changed = true
      session["selected_filters"] = params["selected_filters"]
      @selected_filters = params["selected_filters"]
    else
      @filters_changed = false
      @selected_filters =  tag_ids.collect {|t| t.to_s}
    end
  end

  # GET /events
  # GET /events.json
  def index
    # All upcoming events except for Facebook events belonging to other people 
    # within chosen date range
    @tags = Tag.where(:visible => true).order("name ASC").all

    if !current_user
      @events = Event.joins(:group).where("events.start >= '#{@dates[@selected_date][0]}'
    and events.start < '#{@dates[@selected_date][1]}'").order("start ASC")
      puts 'event counts controller = ' @events.size
    else
      #User is logged in
      @events = Event.joins(:group).where("events.start >= '#{@dates[@selected_date][0]}'
    and events.start < '#{@dates[@selected_date][1]}' and (events.group_id >= 10 or events.group_id in (?))",
                                          @selected_groups_ids).order("start ASC") # TODO fix pagination .page(params[:page]).per(10)
      #checks groups_id > 10; these represent user-created events - allow user to pick category?
      #and (not groups.facebook or groups.name = ?) previously in @events = statement
      @favorites = current_user.favorites.all
    end

    #Filter by selected filters
    if !params["selected_filters"].nil?
      selected_filters = params["selected_filters"]
      filtered_events = []
      for event in @events
        puts event.name
        tags = EventTags.find_all_by_event_id(event.id)
        t = []
        for tag in tags
          t << tag.tag_id.to_s
        end
        if !selected_filters.nil?
          intersection = t & selected_filters
        else
          intersection = []
        end
        if !intersection.empty?
          filtered_events << event
        end
      end
      @events = filtered_events
    else
      @events = []
    end

    #Filter by search term
    if !params["search_term"].nil?
      search_term = params["search_term"].downcase
      filtered_events = []
      for event in @events
        description = (event.description).downcase
        name = (event.name).downcase
        if description.include?(search_term) or name.include?(search_term)
          filtered_events << event
        end
      end
      @events = filtered_events
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @events }
      format.js
    end
  end

  # Called by selecting date
  def select_date
    respond_to do |format|
      format.js {render :nothing => true}
    end
  end

  # Called by checking/unchecking groups in profile
  def select_groups
    # (De)select All
    if params[:selection_data].has_key?(:all)
      if params[:selection_data][:all] == "true"
        current_user.selections = Group.all
      else
        current_user.selections.clear
      end
    else
      params[:selection_data].keys.each do |group_id|
        group = Group.find(group_id)
        if (params[:selection_data][group_id] == "true")
          current_user.selections << group if !current_user.selections.include?(group)
        else
          current_user.selections.delete(group)
        end
      end
    end
    respond_to do |format|
      format.js { render :nothing => true}
    end
  end

  # Profile
  def profile
    @groups = Group.where('not personal and (not facebook or name = ?)',
                          current_user.fb_group).order("name ASC").all
    @selected_groups = current_user.selections
    respond_to do |format|
      format.html
    end
  end

  # Favorite or unfavorite an event, using AJAX
  def favorite
    @event = Event.find(params[:id])
    if !current_user.favorites.include?(@event)
      current_user.favorites << @event
    else
      current_user.favorites.delete(@event)
    end
    respond_to do |format|
      format.html { redirect_to events_path }
      format.js { render :nothing => true }
    end
  end

  # Show only favorited events
  def show_favorites
    @events = @favorites = current_user.favorites.order("start ASC")
    respond_to do |format|
      format.html
      format.json { render :json => @events }
    end
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @event }
    end
  end


  # GET /events/new
  # GET /events/new.json
  def new
    @tags = Tag.where(:visible => true).order("name ASC").all
    @event = Event.new
    respond_to do |format|
      format.html
      format.json { render :json => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @tags = Tag.where(:visible => true).order("name ASC").all
    @event = Event.find(params[:id])
  end

  # POST /events
  # POST /events.json
  def create
    puts "Creating event"
    @event = Event.new(params[:event])
    event_tags = params[:tags] #Could be nil if no tags are selected, TODO: Do we require tags? No for now

    if @event.permalink
      if @event.permalink.length == 0
        @event.permalink = nil
      elsif !@event.permalink.include?("http://")
        @event.permalink = "http://"+@event.permalink
      end
    end
    @event.group_id = Group.find_by_name(params[:group][:name]).id
    respond_to do |format|
      if @event.save

        #add "user-created" tag to each user-created event
        user_created_tag_id = Tag.find_or_create_by_name("User-created").id
        @userCreatedEventTag = EventTags.new(:event_id => @event.id, :tag_id => user_created_tag_id, :tag_name => "user-created")
        if !@userCreatedEventTag.save
          format.html { render :action => "new"}
          format.json { render :json => @event.errors, :status => :unprocessable_entity, :locals => {:tags => ["hello"]}}
          @tags = Tag.where(:visible => true).order("name ASC").all
          format.json { render :json => @tags }
        end
        #add tags that user selected
        if !event_tags.nil?
          event_tags.each do |tag|
            tag_id = Tag.find_by_name(tag).id
            @eventTag = EventTags.new(:event_id => @event.id, :tag_id => tag_id, :tag_name => tag)
            if !@eventTag.save
              format.html { render :action => "new"}
              format.json { render :json => @event.errors, :status => :unprocessable_entity, :locals => {:tags => ["hello"]}}
              @tags = Tag.where(:visible => true).order("name ASC").all
              format.json { render :json => @tags }
            end
          end
          format.html { redirect_to events_path, :notice => 'Event was successfully created.' }
          format.json { render :json => @event, :status => :created, :location => @event }
        else
          format.html { redirect_to events_path, :notice => 'Event was successfully created.' }
          format.json { render :json => @event, :status => :created, :location => @event }
        end
      else
        format.html { render :action => "new"}
        format.json { render :json => @event.errors, :status => :unprocessable_entity, :locals => {:tags => ["hello"]}}
        @tags = Tag.where(:visible => true).order("name ASC").all
        format.json { render :json => @tags }
      end
    end
  end


  # PUT /events/1
  # PUT /events/1.json
  def update
    @event = Event.find(params[:id])
    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { redirect_to @event, :notice => 'Event was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :ok }
    end
  end

  # Feedback emails
  def feedback
    respond_to do |format|
      format.html
    end
  end

  def send_feedback
    feedback = params[:feedback]
    respond_to do |format|
      FeedbackMailer.feedback_email(current_user, feedback).deliver
      flash[:notice] = "Thank you for your feedback!"
      format.html { redirect_to :action => "index" }
    end
  end

  # interests - Choose Tags to initialize groups selection
  def interests
    @tags = Tag.where(:visible => true).order("name ASC").all
    #p 'found' + @tags.count + 'tags'
    respond_to do |format|
      format.html
    end
  end

  def select_filters
    puts "selecting filters"
    @selected_filters = params[:selected_filters]
    #TODO if user logged in, add the selected tags to interests
    respond_to do |format|
      format.html { redirect_to events_path(:selected_filters => @selected_filters) }
    end
  end

  def save_interests
    puts "saving interests"
    @tags = Tag.all.select {|t| params[t.name] }
    tag_ids = @tags.collect {|t| t.id}
    @groups = Group.joins(:tags).where('tags.id in (?)', tag_ids)
    current_user.selections = @groups
    current_user.selections += Group.find_all_by_name("Friends") # What does this do?
    respond_to do |format|
      format.html { redirect_to events_path }
    end
  end
end
