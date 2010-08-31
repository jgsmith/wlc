class AssignmentParticipationsController < ApplicationController
  before_filter :find_assignment_participation, :only => [ :index, :show, :update, :new, :create ]

  def index
    new
    render :action => 'new'
  end

  def new
    @form = @assignment_participation.get_form_info({:user => @user, :real_user => @real_user, :controller => self, :form_authenticity_token => form_authenticity_token })
  end

  def show
    @form = @assignment_participation.get_form_info({:user => @user, :real_user => @real_user, :controller => self, :form_authenticity_token => form_authenticity_token })
    #@form = get_form_info
  end

  def create
    @assignment_participation.process_params({}.update(params))
    @form = @assignment_participation.get_form_info({:user => @user, :real_user => @real_user, :controller => self, :form_authenticity_token => form_authenticity_token })
    #@form = get_form_info
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
      @assignment_participation.process_params({}.update(params))
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
    form = {
      :content => @assignment_participation.view_form
    }
    # XML - need to add values, captions, etc.
    
    args = { }
    if @user != @real_user
      args[:user_id] = @user
      if !params[:module].blank?
        args[:module] = params[:module]
      end
    end
    if !form[:content].blank?

      xml = %{<view><form>} + form[:content] + %{</form></view>}

      tmpl_parser = Fabulator::Template::Parser.new
      parsed = tmpl_parser.parse(@assignment_participation.expr_context, xml)
      form[:content] = parsed.is_a?(String) ? parsed : parsed.to_html(:form => false)

      if @assignment_participation.position == 1
        form[:id] = "participation-s-#{@user.id}"
      else
        form[:id] = "participation-#{@assignment_participation.id}"
      end

      # now we want to convert the form info to something we can use in ExtJS
      # this is temporary

      # should check for an <asset/> element
      form[:fileUpload] = true
     
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
      form[:content] += "<input type='hidden' name='authenticity_token' value='#{form_authenticity_token}'/>"
      form[:content] += "<input type='hidden' name='_method' value='#{form[:method]}' />"

      mod_ctx = @assignment_participation.assignment_module.params_context

      cstate = @assignment_participation.state_def.nil? ? 
                    'start' : @assignment_participation.state_def.name.to_s
       
      submit_label = mod_ctx.eval_expression("sys::/submit-labels/#{cstate}").first
      if !submit_label.nil? && !submit_label.to_s.blank?
        form[:submit] = submit_label.to_s
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
      @assignment_participation.assignment = @assignment
    else
      @assignment_participation = AssignmentParticipation.find(params[:id])
      @assignment = @assignment_participation.assignment_submission.assignment
      find_student
    end
  end
end
