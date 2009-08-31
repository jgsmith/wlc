class MainController < ApplicationController
#  before_filter CASClient::Frameworks::Rails::Filter

  def index
    @user = current_user
    if @user
      n = Time.now
      @current_semesters = Semester.find( :all,
         :conditions => [ 'starts_at <= ? AND ends_at >= ?', n, n ]
      )

      @past_semesters = Semester.find( :all,
         :conditions => [ 'ends_at < ?', n ]
      )

      @future_semesters = Semester.find( :all,
         :conditions => [ 'starts_at > ?', n ]
      )

      if @user
        @currently_teaching = @user.courses.select { |c| @current_semesters.include?(c.semester) }
        @prev_teaching = @user.courses.select { |c| @past_semesters.include?(c.semester) }
        @will_be_teaching = @user.courses.select { |c| @future_semesters.include?(c.semester) }

        @currently_taking = @user.course_participants.select { |cp| cp.level == 0 && @current_semesters.include?(cp.course.semester) }.map { |cp| cp.course }
        @prev_taking = @user.course_participants.select { |cp| cp.level == 0 && @past_semesters.include?(cp.course.semester) }.map { |cp| cp.course }
        @will_be_taking = @user.course_participants.select { |cp| cp.level == 0 && @future_semesters.include?(cp.course.semester) }.map { |cp| cp.course }
      else
        @currently_teaching = [ ]
        @prev_teaching = [ ]
        @will_be_teaching = [ ]

        @currently_taking = [ ]
        @prev_taking = [ ]
      end
    end
  end
end
