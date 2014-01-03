#redirect signin failure to events path
class CustomFailure < Devise::FailureApp
  def redirect_url
    root_path
  end
  def respond
    if http_auth?
      http_auth
    else
      flash[:error] = 'Invalid username or password. Please try again.'
      redirect
    end
  end
end