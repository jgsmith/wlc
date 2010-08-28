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

    params[:level] = params[:level].to_i

    @roster = case params[:level]
      when 0: @course.students
      when 1: @course.designers - @course.assistants
      when 2: @course.assistants
    end
  end

  def update
    @user = current_user
    params[:level] = params[:level].to_i
    if !@user || !(params[:level] == 0 && @course.is_assistant?(@user) ||
       @course.is_instructor?(@user) || @user && @user.is_admin? )
      redirect_to :controller => :courses, :action => :show, :id => @course.id
    end

    # take the list of UINs and add the ones not in the database, making
    # sure the right course participation level is set
    lines = params[:roster].split(/[\n\r]/) - [ '' ]
    uins = [ ]
    lines.each do |line|
      line =~ /^\s*(.*)\s+(\d{9})\s+(T\d+\s+)?(\S+)\s*/
      name = $1
      uin = $2
      email = $4
      bits = email.split('@')
      login = bits[1] == 'tamu.edu' ? bits[0] : uin
      uins << uin
      user = User.find(:first, :conditions => [ 'uin = ?', uin ])
      if user.nil?
        user = User.create({
          :name => name,
          :uin => uin,
          :login => login,
          :email => email
        })
      else
        user.update_attributes({:name => name, :email => email})
      end
      next if user.nil?
      participation = CourseParticipant.find(:first,
        :conditions => [ 'course_id = ? AND user_id = ?',
          @course.id, user.id
        ]
      )
      if participation.nil?
        CourseParticipant.create({
          :course => @course,
          :user_id => user.id,
          :level => params[:level]
        })
      else
        participation.update_attributes({ :level => params[:level] })
      end
    end
    # TODO: remove users not on the list
    redirect_to :controller => :courses, :action => :show, :id => @course
  end

protected

  def find_course
    @course = Course.find(params[:course_id])
  end
end
