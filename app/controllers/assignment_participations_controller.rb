class AssignmentParticipationsController < ApplicationController
#  before_filter CASClient::Frameworks::Rails::Filter

  def index
    new
    render :action => 'new'
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @user = current_user
    @assignment_participation = @assignment.current_module(@user).assignment_participations.first
    @form = get_form_info
  end

  def show
    @user = current_user
    @assignment_participation = AssignmentParticipation.find(params[:id])
    @assignment = @assignment_participation.assignment_submission.assignment

    @form = get_form_info
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @user = current_user
    @assignment_participation = @assignment.current_module(@user).assignment_participations.first
    @assignment_participation.process_params(params)
    respond_to do |format|
      format.html
      format.ext_json { render :json => { :success => true } }
      format.ext_json_html { render :json => ERB::Util::html_escape({:success => true }.to_json) }
    end 
  end

  def update
    @assignment_participation = AssignmentParticipation.find(params[:id])
    @user = current_user
    @assignment = @assignment_participation.assignment_submission.assignment
    # make sure we are the user of this participation and that it's
    # configured_module is the current one
    if @assignment_participation.user == @user && @assignment_participation.position == @assignment.current_module(@user).position
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
    if !form.empty?
      if @assignment_participation.new_record?
        form[:show_url] = assignment_assignment_participations_path(@assignment_participation.assignment)
        form[:method] = 'POST'
      else
        form[:show_url] = assignment_participation_path(@assignment_participation)
        form[:method] = 'PUT'
      end

      if @assignment_participation.position == 1
        form[:id] = 'participation'
      else
        form[:id] = "participation-#{@assignment_participation.id}"
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

      if !form[:items].select{ |i| i[:inputType] == 'file' }.empty?
        form[:url] = form[:show_url] + '?format=ext_json_html'
        form[:fileUpload] = true
      else
        form[:url] = form[:show_url] + '?format=ext_json'
        form[:fileUpload] = false
      end
     
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
end
