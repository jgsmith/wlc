class AssignmentsController < ApplicationController

  before_filter CASClient::Frameworks::Rails::Filter

  def show
    @user = current_user
    @assignment = Assignment.find(params[:id])
    if @assignment.course.user == @user
      # we want to show instructor view of assignment
      render :action => 'show_instructor'
    elsif @assignment.course.is_student?(@user)
      # we show student view of assignment (default)
    else
      render :text => 'Forbidden.', :status => 403
    end
  end
end
