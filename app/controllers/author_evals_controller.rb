class AuthorEvalsController < ApplicationController
  def create
    @user = current_user
    if !params[:assignment_id].blank?
      @assignment = Assignment.find(params[:assignment_id])
      @assignment_submission = AssignmentSubmission.find_by_user_id_and_assignment_id(@user.id, @assignment.id)
      # this is a self-evaluation
      @assignment_submission.author_eval = params[:eval]
      @assignment_submission.save!
    elsif !params[:assignment_participation_id].blank?
      @assignment_participation = AssignmentParticipation.find(params[:assignment_participation_id])
      # this is the author_eval stuff
      if @assignment_participation.assignment_submission.user == @user
        @assignment_participation.author_eval = params[:eval]
        @assignment_participation.save!
      else
        respond_to do |format|
          format.html :text => 'Forbidden!', :status => 403
        end
      end
    else
      # uh oh -- we can't do anything
      respond_to do |format|
        format.html :text => 'Forbidden!', :status => 403
      end
    end

    respond_to do |format|
      format.ext_json { render :json => { :success => true } }
    end
  end
end
