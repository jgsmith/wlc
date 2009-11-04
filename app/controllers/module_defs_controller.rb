class ModuleDefsController < ApplicationController
  before_filter CASClient::Frameworks::Rails::Filter

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_module_def, :only => [ :show, :update ]
  before_filter :require_admin, :except => [ :show, :index ]

  def index
    @module_defs = ModuleDef.find(:all)

    respond_to do |format|
      format.html
      format.json { render :json => @module_defs.to_json }
      format.ext_json { render :json => { :success => true } }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render :json => @module_def.to_json }
      format.ext_json { render :json => @module_def.to_ext_json }
      format.svg
    end
  end
    

protected
  def find_module_def
    @module_def = ModuleDef.find(params[:id])
  end

  def require_admin
    @user = current_user
    return true if @user.is_admin?
    return false
  end
end
