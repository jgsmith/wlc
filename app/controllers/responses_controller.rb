class ResponsesController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found
 }
      format.ext_json { render :json => { :success => false }, :status => :not_f
ound }
    end
  end

  before_filter :find_prompt, :only => [ :new, :create ]
  before_filter :find_response, :only => [ :update, :edit, :destroy, :move_higher, :move_lower ]
  before_filter :require_instructor

  def new
    @response = Response.new
    @response.prompt = @prompt
  end

  def create
    @response = @prompt.responses.build(params[:response])
    @response.save
    redirect_to :action => :index, :rubric_id => @response.prompt.rubric, :controller => 'prompts'
  end

  def edit
  end

  def update
    params[:response].delete('prompt_id')
    @response.update_attributes(params[:response])
    @response.save
    redirect_to :controller => 'prompts', :action => :index, :rubric_id => @response.prompt.rubric
  end

  def move_higher
    @response.move_higher
    redirect_to :action => :show, :id => @response.prompt, :controller => 'prompts'
  end

  def move_lower
    @response.move_lower
    redirect_to :action => :show, :id => @response.prompt, :controller => 'prompts'
  end



  def destroy
    # don't remove if used by an assignment module and we have already
    # had responses recorded
    @response.destroy
    redirect_to :action => :index, :id => @response.prompt, :controller => 'prompts'
  end

protected
  
  # TODO: make sure only the instructor or designer can manage rubrics
  def find_response
    @response = Response.find(params[:id])
  end

  def find_prompt
    @prompt = Prompt.find(params[:prompt_id])
  end
  
  def require_instructor
    # make sure the user has at least one course
    @user.is_admin? || !@user.courses.empty?
  end
end


