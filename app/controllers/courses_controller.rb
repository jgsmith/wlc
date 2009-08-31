class CoursesController < ApplicationController
#  before_filter CASClient::Frameworks::Rails::Filter

  def show
    @user = current_user
    @course = Course.find(params[:id])
  end
end
