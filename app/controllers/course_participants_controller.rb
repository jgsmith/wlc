class CourseParticipantsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_course, :only => [ :show, :create, :update ]

  def show
    @user = current_user
    if !@course.is_assistant?(@user)
      respond_to do |format|
        format.json { render :json => { :success => false }, :status => :forbidden }
        format.ext_json { render :json => { :success => false }, :status => :forbidden }
      end
    end

    respond_to do |format|
      format.ext_json { render :json => @course.course_participants.to_ext_json }
    end
  end

protected

  def find_course
    @course = Course.find(params[:course_id])
  end
end
