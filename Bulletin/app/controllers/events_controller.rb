class EventsController < ApplicationController
  layout 'events'
  #before_filter :authenticate_user!, :only => [:index]
  before_filter :get_memberships, :only => [:new, :create]
  before_filter :initialize_selection, :only => [:index, :search]
  before_filter :manage_groups, :only => [:index, :show_favorites, :search] # only display selected group
  before_filter :manage_selections, :only => [:index, :search]
  before_filter :manage_social, :only => [:index, :show_favorites]
  before_filter :initialize_date, :only => [:index, :search]

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
      @selected_date = session["date"] || "Today"
    end
  end

  # GET /events
  # GET /events.json
  def index
    # All upcoming events except for Facebook events belonging to other people 
    # within chosen date range
    puts "selected groups: "
    puts @selected_groups
    puts @dates[@selected_date]
    @events = Event.joins(:group).where("events.start >= '#{@dates[@selected_date][0]}'
    and events.start < '#{@dates[@selected_date][1]}'", @selected_groups_ids).order("start ASC")
    #@events = Event.all
    puts "events: "
    puts @events

    return true unless current_user
    @events = Event.joins(:group).where("events.start >= '#{@dates[@selected_date][0]}' 
    and events.start < '#{@dates[@selected_date][1]}'
    and (not groups.facebook or groups.name = ?) and events.group_id in (?)",
                                        current_user.fb_group, @selected_groups_ids).order("start ASC") # TODO fix pagination .page(params[:page]).per(10)

    @favorites = current_user.favorites.all
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
    # (De)Select All
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
    @event = Event.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    @event = ["EVENT 1", "EVENT 2"]
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(params[:event])
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
        puts "EVENT:"
        puts @event
        format.html { redirect_to events_path, :notice => 'Event was successfully created.' }
        format.json { render :json => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.json { render :json => @event.errors, :status => :unprocessable_entity }
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

  def save_interests
    @tags = Tag.all.select {|t| params[t.name] }
    tag_ids = @tags.collect {|t| t.id}
    @groups = Group.joins(:tags).where('tags.id in (?)', tag_ids)
    current_user.selections = @groups
    current_user.selections += Group.find_all_by_name("Friends") # Who doesn't like friends?
    respond_to do |format|
      format.html { redirect_to events_path }
    end
  end
end
