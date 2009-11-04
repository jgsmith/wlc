class AssignmentModulesController < ApplicationController

  before_filter CASClient::Frameworks::Rails::Filter

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :index, :new, :create ]

  before_filter :find_assignment_module, :only => [ :show, :update, :edit ]

  before_filter :require_designer

  
  def index
    respond_to do |format|
      format.html
      format.ext_json { render :json => @assignment.configured_modules(nil).to_ext_json }
    end
  end


  def show
  end

  def new
    @assignment_module = AssignmentModule.new
    @assignment_module.assignment = @assignment
  end

  def create
  end

  def edit
  end

  def update
  end

protected

  def require_designer
    if !@assignment.course.is_designer?(@user)
      respond_to do |format|
        format.json { render :json => { :success => false }, :status => :forbidden }
        format.ext_json { render :json => { :success => false }, :status => :forbidden }
        format.html { render :text => 'Forbidden!', :status => :forbidden }
      end
    end
  end

  def find_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def find_assignment_module
    @assignment_module = AssignmentModule.find(params[:id])
    @assignment = @assignment_module.assignment
  end
end
