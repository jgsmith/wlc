class AssignmentModulesController < ApplicationController

  before_filter CASClient::Frameworks::Rails::Filter

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :index, :new, :create ]

  before_filter :find_assignment_module, :only => [ :show, :update, :edit, :destroy, :move_higher, :move_lower, :edit_params, :update_params ]

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
    @assignment_module = AssignmentModule.new
    @assignment_module.assignment = @assignment
    @assignment_module.module_type = params[:assignment_module][:module_type].to_i
    @assignment_module.tag = params[:assignment_module][:tag]
    @assignment_module.duration = 0
    @assignment_module.number_participants = 1
    case @assignment_module.module_type
      when -1: @assignment_module.name = 'Private Messaging'
      when  0: @assignment_module.name = 'Informational'
      else     @assignment_module.name = @assignment_module.module_def.name
    end
    @assignment_module.save!

    redirect_to :action => :index, :assignment_id => @assignment
  end

  def edit
  end

  def update
  end

  def edit_params
  end

  def update_params
    # we want to make sure we only get things that are in the form
    form = @assignment_module.params_form
    doc = LibXML::XML::Document.string form
    names = doc.find('//input/@name').collect{ |n| n.value }
    ctx = @assignment_module.configured_module(nil).context
    ctx.root.roots['sys'] = ctx.root.anon_node(nil)
    ctx.root.roots['sys'].axis = 'sys'
    c = ctx.with_root(ctx.root.roots['sys'])
    data = { }
    names.each do |n|
      next unless n =~ /^params\.(.*)$/
      nom = $1
      data[nom] = params[n]
    end
    c.merge_data({ 'params' => data })
    @assignment_module.params = c.root
    @assignment_module.save
    redirect_to :action => :edit_params, :id => @assignment_module
  end

  def destroy
    @assignment.assignment_modules.delete(@assignment_module)
    @assignment_module.delete
    redirect_to :action => :index, :assignment_id => @assignment
  end

  def move_higher
    @assignment_module.move_higher
    redirect_to :action => :index, :assignment_id => @assignment
  end 

  def move_lower
    @assignment_module.move_lower
    redirect_to :action => :index, :assignment_id => @assignment
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
