class AssignmentsController < ApplicationController

  before_filter CASClient::Frameworks::Rails::Filter

  def show
    @user = current_user
    @assignment = Assignment.find(params[:id])
  end
end
