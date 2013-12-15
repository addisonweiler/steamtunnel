class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :set_timezone  

  def set_timezone  
    # current_user.time_zone #=> 'Central Time (US & Canada)'  
    Time.zone = 'Pacific Time (US & Canada)'  
  end
  
  # To ensure that the flash message appears
  def after_resending_confirmation_instructions_path_for(resource)
    new_user_session_path
  end
  
end
