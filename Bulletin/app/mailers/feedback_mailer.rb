class FeedbackMailer < ActionMailer::Base
  default from: "welcome.steamtunneling@gmail.com"
  #default from: "johnluttig@gmail.com"

  def feedback_email(user, feedback)
    @feedback = feedback
    @user = user
    mail(:to => "feedback@steamtunneling.com", :subject => "Feedback from #{@user.name}")
  end
end
