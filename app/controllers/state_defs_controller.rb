class StateDefsController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_state_def, :only => [ :show, :update, :edit ] 
  before_filter :require_admin, :except => [ :show, :index ]

  def show
    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @state_def.update_attributes(params[:state_def])
    @state_def.save!
    redirect_to :controller => 'module_defs', :action => 'show', :id => @state_def.module_def
  end

protected
  def find_state_def
    if params[:id]
      @state_def = StateDef.find(params[:id])
      @module_def = @state_def.module_def
    elsif params[:module_def_id]
      @module_def = ModuleDef.find(params[:module_def_id])
      if !@module_def.nil?
        nom = nil
        if params[:state_def]
          nom = params[:state_def][:name]
        else
          nom = params[:state]
        end
        @state_def = @module_def.state_defs.find(:first,
          :conditions => [ 'name = ?', nom ]
        )
        if @state_def.nil? && @module_def.references_state?(nom)
          @state_def = @module_def.state_defs.build({
            :name => nom
          })
        end
      end
    end

    raise ActiveRecord::RecordNotFound if @state_def.nil?
  end

  def require_admin
    @user = current_user
    return true if @user.is_admin?
    return false
  end
end
