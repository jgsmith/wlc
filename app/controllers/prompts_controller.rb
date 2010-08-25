class PromptsController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found
 }
      format.ext_json { render :json => { :success => false }, :status => :not_f
ound }
    end
  end

  before_filter :find_rubric, :only => [ :index, :new, :create ]
  before_filter :find_prompt, :only => [ :show, :update, :edit, :destroy, :move_higher, :move_lower ]
  before_filter :require_instructor

  def index
    @prompts = @rubric.prompts
  end

  def show
    
  end

  def new
    @prompt = Prompt.new
    @prompt.rubric = @rubric
  end

  def create
    @prompt = @rubric.prompts.build(params[:prompt])
    @prompt.save
    redirect_to :action => :index, :rubric_id => @rubric, :controller => 'prompts'
  end

  def edit
  end

  def update
    @rubric.update_attributes(params[:rubric])
    @rubric.save
    redirect_to :action => :show, :id => @rubric
  end

  def move_higher
    @prompt.move_higher
    redirect_to :action => :index, :rubric_id => @prompt.rubric, :controller => 'prompts'
  end

  def move_lower
    @prompt.move_lower
    redirect_to :action => :index, :rubric_id => @prompt.rubric, :controller => 'prompts'
  end



  def destroy
    # don't remove if used by an assignment module and we have already
    # had responses recorded
    @prompt.destroy
    redirect_to :action => :index, :rubric_id => @prompt.rubric, :controller => 'prompts'
  end

protected
  
  def find_rubric
    if @user.is_admin?
      @rubric = Rubric.find(params[:rubric_id])
    else
      @rubric = @user.rubrics.find(params[:rubric_id])
    end
  end

  def find_prompt
    @prompt = Prompt.find(params[:id])
  end
  
  def require_instructor
    # make sure the user has at least one course
    @user.is_admin? || !@user.courses.empty?
  end
end


