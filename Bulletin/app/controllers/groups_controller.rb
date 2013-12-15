class GroupsController < ApplicationController
  FIELDS = {
    :group_name => /Group:(.*)/i,
    :title => /Title:(.*)/i,
    :start => /Start:(.*)/i,
    :finish => /Finish:(.*)/i,
    :location => /Location:(.*)/i,
    :link => /Link:(.*)/i,
    :description => /Description:(.*)/i
  }

  def parse_field(regex, text)
    value = text.match(regex)
    return value.present? ? value[1].strip : nil
  end

  # Parse Emails from cloudmailin
  def email
    text = params[:plain]..gsub!(/\*/, '')
    return unless text.present?

    parsed_fields = {}
    for field, regex in FIELDS
      parsed_fields[field] = parse_field(regex, text)
    end
    parsed_fields[:start] = Event.PSTtoUTC(parsed_fields[:start])
    parsed_fields[:finish] = Event.PSTtoUTC(parsed_fields[:finish])
    group = Group.find_or_create_by_name(parsed_fields[:group_name])
    parsed_fields[:group_id] = group.id

    Event.create(parsed_fields)

    respond_to do |format|
      format.html { render :nothing => true}
    end
  end


  # GET /groups
  # GET /groups.json
  def index
    @groups = Group.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = Group.find_by_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find_by_id(params[:id])
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, notice: 'Group was successfully created.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find_by_id(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
        format.html { redirect_to @group, notice: 'Group was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find_by_id(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :ok }
    end
  end
end
