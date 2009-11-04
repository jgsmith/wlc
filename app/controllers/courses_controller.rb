class CoursesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
      format.ext_json_html { render :json => ERB::Util::html_escape({ :success => false }.to_json), :status => :not_found }
    end
  end

  before_filter :find_course, :only => [ :show ]

  def index
    @user = current_user
    if @user
      n = Time.now.utc
      @current_semesters = Semester.find( :all,
         :conditions => [ 'utc_starts_at <= ? AND utc_ends_at >= ?', n, n ]
      )

      @past_semesters = Semester.find( :all,
         :conditions => [ 'utc_ends_at < ?', n ]
      )

      @future_semesters = Semester.find( :all,
         :conditions => [ 'utc_starts_at > ?', n ]
      )

      @currently_teaching = @user.courses.find(:all, :conditions => ['semester_id IN (?)', @current_semesters])
      @prev_teaching = @user.courses.find(:all, :conditions => ['semester_id IN (?)', @past_semesters])
      @will_be_teaching = @user.courses.find(:all, :conditions => ['semester_id IN (?)', @future_semesters])

      @currently_assisting = @user.course_participants.find(:all,:joins => [ :course ], :conditions => ['level > 0 AND courses.semester_id in (?)', @current_semesters], :select => 'course_participants.*').collect { |cp| cp.course }
      @prev_assisting = @user.course_participants.find(:all,:joins => [ :course ], :conditions => ['course_participants.level > 0 AND courses.semester_id in (?)', @past_semesters], :select => 'courses.*').collect { |cp| cp.course }
      @future_assisting = @user.course_participants.find(:all,:joins => [ :course ], :conditions => ['course_participants.level > 0 AND courses.semester_id in (?)', @future_semesters], :select => 'courses.*').collect { |cp| cp.course }

      @currently_taking = @user.course_participants.find(:all,:joins => [ :course ], :conditions => ['course_participants.level = 0 AND courses.semester_id in (?)', @current_semesters], :select => 'course_participants.*').collect{ |cp| cp.course }
      @prev_taking = @user.course_participants.find(:all,:joins => [ :course ], :conditions => ['course_participants.level = 0 AND courses.semester_id in (?)', @past_semesters], :select => 'course_participants.*').collect{ |cp| cp.course }
      @future_taking = @user.course_participants.find(:all,:joins => [ :course ], :conditions => ['course_participants.level = 0 AND courses.semester_id in (?)', @future_semesters], :select => 'course_participants.*').collect{ |cp| cp.course }
    else
      @current_semesters = [ ]
      @past_semesters = [ ]
      @future_semesters = [ ]

      @currently_teaching = [ ]
      @prev_teaching = [ ]
      @will_be_teaching = [ ]

      @currently_taking = [ ]
      @prev_taking = [ ]
    end
  end

  def show
    @assignments = @course.assignments
  end

protected

  def find_course
    @course = Course.find(params[:id])
  end
end
