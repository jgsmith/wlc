class InstructorEvalsController < ApplicationController
  def create
    if !params[:assignment_submission_id].blank?
      @assignment_submission = AssignmentSubmission.find(params[:assignment_submission_id])
      @assignment = @assignment_submission.assignment
      if @assignment.course.is_assistant?(@user)
        @assignment_submission.instructor_eval = params[:eval]
        @assignment_submission.save!
        respond_to do |format|
          format.ext_json { render :json => { :success => true } }
        end
      else
        render :text => 'Forbidden!', :status => :forbidden
      end
    else
      # uh oh -- we can't do anything
      render :text => 'Forbidden!', :status => 403
    end
  end
end
