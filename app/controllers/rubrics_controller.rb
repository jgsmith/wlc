class RubricsController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found
 }
      format.ext_json { render :json => { :success => false }, :status => :not_f
ound }
    end
  end

  before_filter :find_rubric, :only => [ :show ]
  before_filter :find_own_rubric, :only => [ :update, :edit, :destroy ]
  before_filter :find_course, :only => [ :new, :create, :index ]
  before_filter :require_designer, :only => [ :new, :create, :update, :edit, :index ]

  def index
    @rubrics = @course.rubrics
  end

  def show
    
  end

  def new
    @rubric = Rubric.new
  end

  def create
    @rubric = Rubric.new
    @rubric.course = @course
    @rubric.update_attributes(params[:rubric])
    @rubric.save
    redirect_to :action => :show, :id => @rubric
  end

  def edit
  end

  def update
    @rubric.update_attributes(params[:rubric])
    @rubric.save
    redirect_to :action => :show, :id => @rubric
  end

  def destroy
    # don't remove if used by an assignment module
  end

protected
  
  def find_own_rubric
    @rubric = Rubric.find(params[:id])
    if !(@user.is_admin? || @rubric.course.is_designer?(@user))
      @rubric = nil
      raise ActiveRecord::RecordNotFound
    end
  end

  def find_rubric
    @rubric = Rubric.find(params[:id])
  end

  def find_course
    @course = Course.find(params[:course_id])
  end
  
  def require_designer
    # make sure the user has at least one course
    return true if @user.is_admin?
    if @rubric.nil?
      return !@user.courses.empty?
    else
      return @rubric.course.is_designer?(@user)
    end
  end
end


