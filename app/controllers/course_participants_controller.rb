class CourseParticipantsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_course, :only => [ :show, :edit, :update ]

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

  def edit
    @user = current_user
    if !@user || !(params[:level] == 0 && @course.is_assistant?(@user) ||
       @course.is_instructor?(@user) || @user && @user.is_admin? )
      redirect_to :controller => :courses, :action => :show, :id => @course.id
    end

    @roster = case params[:level]
      when 0: @course.students
      when 1: @course.designers
      when 2: @course.assistants
    end
  end

  def update
    @user = current_user
    if !@user || !(params[:level] == 0 && @course.is_assistant?(@user) ||
       @course.is_instructor?(@user) || @user && @user.is_admin? )
      redirect_to :controller => :courses, :action => :show, :id => @course.id
    end

    # take the list of UINs and add the ones not in the database, making
    # sure the right course participation level is set
  end

protected

  def find_course
    @course = Course.find(params[:course_id])
  end
end
