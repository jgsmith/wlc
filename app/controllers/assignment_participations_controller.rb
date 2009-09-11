class AssignmentParticipationsController < ApplicationController
#  before_filter CASClient::Frameworks::Rails::Filter

  def index
    new
    render :action => 'new'
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @user = current_user
    @assignment_participation = @assignment.current_module(@user).assignment_participations.first
  end

  def show
    @user = current_user
    @assignment_participation = AssignmentParticipation.find(params[:id])
    @assignment = @assignment_participation.assignment_submission.assignment
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @user = current_user
    @assignment_participation = @assignment.current_module(@user).assignment_participations.first
    @assignment_participation.process_params(params)
    respond_to do |format|
      format.html
      format.ext_json { render :json => { :success => true } }
      format.ext_json_html { render :json => ERB::Util::html_escape({:success => true }.to_json) }
    end 
  end

  def update
    @assignment_participation = AssignmentParticipation.find(params[:id])
    @user = current_user
    @assignment = @assignment_participation.assignment_submission.assignment
    # make sure we are the user of this participation and that it's
    # configured_module is the current one
    if @assignment_participation.user == @user && @assignment_participation.position == @assignment.current_module(@user).position
      @assignment_participation.process_params(params)
      respond_to do |format|
        format.html
        format.ext_json { render :json => { :success => true } }
        format.ext_json_html { render :json => ERB::Util::html_escape({:success => true }.to_json) }
      end 
    else
      respond_to do |format|
        format.html
        format.ext_json { render :json => { :success => false, :message => 'You are not the participant or your participation in this phase of the assignment has expired.' } }
        format.ext_json_html { render :json => ERB::Util::html_escape({:success => false, :message => 'You are not the participant or your participation in this phase of the assignment has expired.' }.to_json) }
      end 
    end
  end
end