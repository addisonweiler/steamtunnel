class ExperimentsController < ApplicationController
  layout 'static'
  
  def index
    @name = params[:name]
    @user_id = params[:id]
    @exp = Experiment.new(:name => @name, :user_id => @user_id)
    @exp.save
    respond_to do |format|
      format.html { render @name }
    end
  end
  
end
