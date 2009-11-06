class AssignmentParticipationsController < ApplicationController
  before_filter :find_assignment, :only => [ :new, :create ]
  #before_filter :find_student, :only => [ :new, :create, :show, :update ]
  before_filter :find_assignment_participation, :only => [ :index, :show, :update, :new, :create ]

  def index
    new
    render :action => 'new'
  end

  def new
    @form = get_form_info
  end

  def show
    @form = get_form_info
  end

  def create
    @assignment_participation = @assignment.current_module(@user).assignment_participations.first
    @assignment_participation.process_params(params)
    respond_to do |format|
      format.html
      format.ext_json { render :json => { :success => true } }
      format.ext_json_html { render :json => ERB::Util::html_escape({:success => true }.to_json) }
    end 
  end

  def update
    #@assignment_participation = AssignmentParticipation.find(params[:id])
    #@assignment = @assignment_participation.assignment_submission.assignment
    # make sure we are the user of this participation and that it's
    # configured_module is the current one
    if @assignment_participation.user == @user && (@assignment_participation.position == @assignment.current_module(@user).position || @assignment_participation.position == params[:module]+1 && @user != @real_user)
      @assignment_participation.process_params(params)
      respond_to do |format|
        format.html
        format.ext_json { render :json => { :success => true } }
        format.ext_json_html { render :json => ERB::Util::html_escape({:success => true }.to_json) }
      end 
    else
      respond_to do |format|
        format.html
        format.ext_json { render :json => { :success => false, :message => 'You are not the participant or your participation in this phase of the assignment has expired.' } }
        format.ext_json_html { render :json => ERB::Util::html_escape({:success => false, :message => 'You are not the participant or your participation in this phase of the assignment has expired.' }.to_json) }
      end 
    end
  end

protected

  def get_form_info
    form = @assignment_participation.view_form
    args = { }
    if @user != @real_user
      args[:user_id] = @user
      if !params[:module].blank?
        args[:module] = params[:module]
      end
    end
    if !form.empty?

      if @assignment_participation.position == 1
        form[:id] = "participation-s-#{@user.id}"
      else
        form[:id] = "participation-#{@assignment_participation.id}"
      end

      if !form[:items].select{ |i| i[:inputType] == 'file' }.empty?
        form[:fileUpload] = true
      else
        form[:fileUpload] = false
      end
     
      if @assignment_participation.new_record?
        args[:assignment_id] = @assignment_participation.assignment
        form[:show_url] = assignment_assignment_participations_path(args)
        args[:format] = 'ext_json' + (form[:fileUpload] ? '_html' : '')
        form[:url] = assignment_assignment_participations_path(args)
        form[:method] = 'POST'
      else
        args[:action] = 'show'
        args[:controller] = 'assignment_participations'
        args[:id] = @assignment_participation
        form[:show_url] = url_for(args) # assignment_participation_path(args)
        args[:format] = 'ext_json' + (form[:fileUpload] ? '_html' : '')
        form[:url] = url_for(args)
        form[:method] = 'PUT'
      end

      form[:items] << {
        :inputType => 'hidden',
        :name => 'authenticity_token',
        :value => form_authenticity_token,
        :xtype => 'field'
      }

      form[:items] << {
        :inputType => 'hidden',
        :name => '_method',
        :value => form[:method],
        :xtype => 'field'
      }

      mod_params = @assignment_participation.configured_module.params
      if !mod_params.nil? && !mod_params.empty?
        form[:items].each do |i|
          if !mod_params[:field_labels][i[:name]].blank?
            i[:fieldLabel] = mod_params[:field_labels][i[:name]]
          end
        end

        cstate = @assignment_participation.state_def.nil? ? 
                    :start : @assignment_participation.state_def.name.to_sym
       
        if !mod_params[:submit_labels][cstate].blank?
          form[:submit] = mod_params[:submit_labels][cstate]
        end
      end
    end
    form
  end

protected

  def find_assignment
    logger.info("find_assignment")
    @assignment = Assignment.find(params[:assignment_id])
  end

  def find_student
    @real_user = @user
    if !params[:user_id].blank?
      find_assignment if @assignment.nil?
      @user = User.find(params[:user_id])
      if !@assignment.course.is_student?(@user) || 
         !@assignment.course.is_assistant?(@real_user)
        return false
      end
    end
  end

  def find_assignment_participation
    if params[:id].blank?
      find_assignment
      find_student
      if params[:module].blank?
        @assignment_participation = @assignment.current_module(@user).assignment_participations.first
      elsif @assignment.course.is_assistant?(@real_user)
        @assignment_participation = @assignment.configured_modules(@user)[params[:module].to_i].assignment_participations(true).first
      end
    else
      @assignment_participation = AssignmentParticipation.find(params[:id])
      @assignment = @assignment_participation.assignment_submission.assignment
      find_student
    end
  end
end
