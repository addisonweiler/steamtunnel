class MyDevise::RegistrationsController < Devise::RegistrationsController
  protected
    def after_inactive_sign_up_path_for(resource)
      flash[:notice] += " Please check your email."
      new_user_session_path
    end
end