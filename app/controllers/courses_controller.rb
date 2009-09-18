class CoursesController < ApplicationController
#  before_filter CASClient::Frameworks::Rails::Filter

  def show
    @user = current_user
    @course = Course.find(params[:id])
    if @course.user == @user && ENV['RAILS_ENV'] == 'development'
      render :action => 'show_instructor'
    end
  end
end
