class MyDevise::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    puts "HELLO WORLD"
begin
    # You need to implement the method below in your model
    # TODO better way to do levels of authentication?
    session["devise.facebook_data"] = request.env["omniauth.auth"]
    info = session["devise.facebook_data"]["extra"]["raw_info"]
    @user = current_user
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Facebook"
      token = session["devise.facebook_data"]["credentials"]["token"]
      @user.fb_token = token
      @user.fb_id = info["id"]
      @user.name = info["name"]
      # Get Friends
      @graph = Koala::Facebook::API.new(token)
      friends = @graph.get_connections("me", "friends")
      @user.friends = friends.collect {|info| info["name"]}
      @user.save
      # Find/create group for user's facebook events
      name = "#{info['first_name']}'s Facebook Events"
      group = Group.find_by_name(name)
      if group.nil?
        group = Group.create(:name => name, :facebook => true)
        group.users << @user # TODO should people be members of their FB group?
        group.tags << Tag.find_by_name("Facebook")
        group.thumbnail = "Facebook.png"
        @user.selections << group
        # Update name of personal group
        personalGroup = Group.find_by_name(@user.email)
        if !personalGroup.nil?
          personalGroup.name = @user.name
          personalGroup.save
        end
      end
      # Create unseen events and link all events to user's Facebook Events group
      Event.pollUser(@user, group)
      sign_in_and_redirect @user, :event => :authentication
    else
      puts "redirecting to new user registration."
      redirect_to new_user_registration_url
    end
end
  end
end