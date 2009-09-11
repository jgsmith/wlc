class ParticipantEvalsController < ApplicationController
  def create
    @user = current_user
    @assignment_participation = AssignmentParticipation.find(params[:assignment_participation_id])
    # this is the author_eval stuff
    if @assignment_participation.user != @user
      respond_to do |format|
        format.html :text => 'Forbidden!', :status => 403
      end
    else
      @assignment_participation.participant_eval = params[:eval]
      @assignment_participation.save!

      respond_to do |format|
        format.ext_json { render :json => { :success => true } }
      end
    end
  end
end
