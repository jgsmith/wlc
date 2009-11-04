# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ExtScaffold

  before_filter :cas_auth
  before_filter :set_users

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password, :password_confirmation

  def set_users
    @actual_user = actual_user
    @user = current_user

    @current_assignments = [ ]
    if @user
      current_courses = @user.course_participants.find(:all,
        :joins => %{
          LEFT JOIN courses ON courses.id = course_participants.course_id
          LEFT JOIN semesters ON semesters.id = courses.semester_id
        },
        :conditions => [
          %{
            semesters.utc_starts_at <= ? AND
            semesters.utc_ends_at >= ?
          }, Time.now(), Time.now()
        ]
      ).collect{|cp| cp.course} + @user.courses.find(:all,
        :joins => 'LEFT JOIN semesters ON semesters.id = courses.semester_id',
        :conditions => [
          %{
            semesters.utc_starts_at <= ? AND
            semesters.utc_ends_at >= ?
          }, Time.now(), Time.now()
        ]
      )
      @current_assignments = current_courses.select{|c|
        c.has_current_assignment?
      }
    end
  end

  def self.no_auth_required
    CASClient::Frameworks::Rails::Filter.use_gatewaying(self)
  end

  def cas_auth
    CASClient::Frameworks::Rails::Filter.filter(self)
  end
end
