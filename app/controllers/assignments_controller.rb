class AssignmentsController < ApplicationController

#  include ExtScaffold

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :show, :update, :edit, :trust, :move_higher, :move_lower, :destroy ]
  before_filter :find_course,     :only => [ :index, :new, :create ]
  before_filter :require_assistant, :only => [ :trust, :edit, :update, :move_higher, :move_lower, :destroy ]
  before_filter :require_instructor, :only => [ :new, :create ]

  def index
    @assignments = @course.assignments
    respond_to do |format|
      format.ext_json { render :json => @assignments.to_ext_json(:class => Assignment) }
    end
  end

  def move_higher
    @assignment.move_higher
    redirect_to :action => :show, :id => @assignment.course, :controller => 'courses'
  end
  
  def move_lower
    @assignment.move_lower
    redirect_to :action => :show, :id => @assignment.course, :controller => 'courses'
  end

  def destroy
    @assignment.destroy
    redirect_to :action => :show, :id => @assignment.course, :controller => 'courses'
  end


  def trust
    @needed_papers = [ ]
    @assignment.calculate_all_scores unless @assignment.scores_calculated?
    @needed_papers = @assignment.assignment_submissions.find(:all,
      :conditions => [ 'trust < 1.e-5' ]
    ).map{ |as| @assignment.assignment_submissions.find(:all,
      :joins => [ :assignment_participations ],
      :conditions => [ 'assignment_participations.user_id = ? and assignment_participations.tag = ?', as.user.id, @assignment.eval_tag ]
    ) + (@assignment.author_rubric.nil? ? [] : [ as ]) }.flatten.uniq
  end

  def show
    if @assignment.course.is_assistant?(@user)
      @missing_students = @assignment.not_participating
      @configured_modules_info = [ ]
      @grade_store_fields = [ 'id', 'name', 'is_participant' ]

      # we want to show instructor view of assignment
      @performance_store_fields = [ 'id', 'name', 'is_participant', 'progress_info', 'grading', 'messages_url' ]
      @performance_grid_columns = [
        { :id => 'name', :header => 'Name', :width => 200, :sortable => true, :dataIndex => 'name', :xtype => 'participantnamecolumn' },
      ]
      @grades_grid_columns = [
        { :id => 'name', :header => 'Name', :width => 200, :sortable => true, :dataIndex => 'name', :xtype => 'participantnamecolumn' },
      ]

      if @assignment.calculate_trust?
        @grades_grid_columns << {
          :id => 'trust', :header => 'Trust', :dataIndex => 'trust'
        }
        @grade_store_fields << 'trust'
      end

      @expander_template = %{
<table width="100%" border="0">
  <tr>
    <th width="50%" align="center">Portfolio</th>
    <th width="50%" align="center">Grading</th>
  </tr>
  <tr>
    <td width="50%">
      <p><a href="{messages_url}" target="_new">Messages</a></p>
      {progress_info}
    </td>
    <td width="50%">{grading}</td>
  </tr>
</table>}

      grade_expander_info = [ ]

      @assignment.configured_modules(nil).each do |m|
        @configured_modules_info << {
          :flex => m.duration,
          :html => 'Name: ' + m.name,
          :xtype => 'panel'
        }

        if m.has_evaluation?
          m_grade_x = {
            :title => m.name,
            :size => m.number_participants
          }
          if !m.author_name.blank? && m.participant_rubric
            m_grade_x[:author_prompts] = m.participant_rubric.prompts.collect{|x| x.tag}
            m_grade_x[:author_prefix] = 'author_' + m.position.to_s + '_'
            m_grade_x[:author_name] = m.author_name
            m.number_participants.times do |i|
              nm = 'author_' + m.position.to_s + '_' + i.to_s
              @performance_store_fields << nm
              @grade_store_fields << nm
              m.author_rubric.prompts.each do |p|
                @grade_store_fields << nm + '_rubric_' + p.tag
              end
              @performance_grid_columns << {
               :id => nm, :header => m.author_name + ' #' + (i+1).to_s,
               :sortable => true, :dataIndex => nm
              }
              @grades_grid_columns << {
               :id => nm, :header => m.author_name + ' #' + (i+1).to_s,
               :sortable => true, :dataIndex => nm
              }
            end
            @grades_grid_columns << {
               :id => 'author_' + m.position.to_s + '_avg',
               :header => m.author_name + ' Avg', :sortable => true,
               :dataIndex => 'author_' + m.position.to_s + '_avg'
            }
            @grade_store_fields << 'author_' + m.position.to_s + '_avg'
          end
          if !m.participant_name.blank? && m.author_rubric
            m_grade_x[:participant_prompts] = m.author_rubric.prompts.collect{|x| x.tag}
            m_grade_x[:participant_prefix] = 'participant_' + m.position.to_s + '_'
            m_grade_x[:participant_name] = m.participant_name
            m.number_participants.times do |i|
              nm = 'participant_' + m.position.to_s + '_' + i.to_s
              @performance_store_fields << nm
              @grade_store_fields << nm
              m.participant_rubric.prompts.each do |p|
                @grade_store_fields << nm + '_rubric_' + p.tag
              end
              @performance_grid_columns << {
               :id => nm, :header => m.participant_name + ' #' + (i+1).to_s,
               :sortable => true, :dataIndex => nm
              }
              @grades_grid_columns << {
               :id => nm, :header => m.participant_name + ' #' + (i+1).to_s,
               :sortable => true, :dataIndex => nm
              }
            end
            @grades_grid_columns << {
               :id => 'participant_' + m.position.to_s + '_avg',
               :header => m.participant_name + ' Avg', :sortable => true,
               :dataIndex => 'participant_' + m.position.to_s + '_avg'
            }
            @grade_store_fields << 'participant_' + m.position.to_s + '_avg'
            grade_expander_info << m_grade_x
          end
        end
      end
      if @assignment.participant_rubric && !@assignment.author_name.nil?
        nm = 'participant_' + @assignment.configured_modules(nil).last.position.to_s
        grade_expander_info << {
          :title => @assignment.eval_name,
          :size => @assignment.number_evaluations,
          :author_name => @assignment.author_name,
          :author_prefix => nm + '_',
          :author_prompts => @assignment.participant_rubric.prompts.collect{|x| x.tag }
        }
        @assignment.number_evaluations.times do |i|
          @grade_store_fields << nm + '_' + i.to_s
          @assignment.participant_rubric.prompts.each do |p|
            @grade_store_fields << nm + '_' + i.to_s + '_rubric_' + p.tag
          end
        end
      end
      if !@assignment.author_rubric.nil?
        grade_expander_info << {
          :author_name => 'Self Eval',
          :size => 1,
          :title => '',
          :author_prefix => 'self_eval_',
          :author_prompts => @assignment.author_rubric.prompts.collect{|x| x.tag}
        }
        @grades_grid_columns << {
          :id => 'self_eval', :header => 'Self Eval', :sortable => true,
          :dataIndex => 'self_eval' 
        } 
        @grade_store_fields << 'self_eval'
      end
      @grades_grid_columns << {
          :id => 'final', :header => 'Composite', :sortable => true,
          :dataIndex => 'final' 
      }
      @grade_store_fields << 'final'

      max_prompts = 0
      grade_expander_info.each do |x|
        if x[:author_prompts]
          max_prompts = x[:author_prompts].length > max_prompts ?
                        x[:author_prompts].length :
                        max_prompts
        end
        if x[:participant_prompts]
          max_prompts = x[:participant_prompts].length > max_prompts ?
                        x[:participant_prompts].length :
                        max_prompts
        end
      end
      @grade_expander_template = %{
        <table border="0" width="100%">
      }
      grade_expander_info.each do |x|
        @grade_expander_template = @grade_expander_template + %{
          <tr><td align="center" colspan="#{max_prompts+1}"><h2>#{x[:title]}</h2></td></tr>
        }
        if x[:author_prompts]
          @grade_expander_template = @grade_expander_template + %{
            <tr><td colspan="#{max_prompts+1}"><h3>#{x[:author_name]}</h3></td></tr>
            <tr><td></td>
          }
          x[:author_prompts].each do |t|
            @grade_expander_template = @grade_expander_template +
              %{<td>#{t}</td>}
          end
          @grade_expander_template = @grade_expander_template +
            %{</tr>}

          x[:size].times do |i|
            @grade_expander_template = @grade_expander_template +
              %{<tr><td>{#{x[:author_prefix]}#{i}_name}</td>}
            x[:author_prompts].each do |t|
              @grade_expander_template = @grade_expander_template +
                %{<tr><td>{#{x[:author_prefix]}#{i}_rubric_#{t}}}
            end
            @grade_expander_template = @grade_expander_template +
              %{</tr>}
          end
        end
        if x[:participant_prompts]
          @grade_expander_template = @grade_expander_template + %{
            <tr><td colspan="#{max_prompts+1}"><h3>#{x[:participant_name]}</h3></td></tr>
            <tr><td></td>
          }
          x[:participant_prompts].each do |t|
            @grade_expander_template = @grade_expander_template +
              %{<td>#{t}</td>}
          end
          @grade_expander_template = @grade_expander_template +
            %{</tr>}

          x[:size].times do |i|
            @grade_expander_template = @grade_expander_template +
              %{<tr><td>{#{x[:participant_prefix]}#{i}_name}</td>}
            x[:participant_prompts].each do |t|
              @grade_expander_template = @grade_expander_template +
                %{<tr><td>{#{x[:participant_prefix]}#{i}_rubric_#{t}}}
            end
            @grade_expander_template = @grade_expander_template +
              %{</tr>}
          end
        end
      end
      @grade_expander_template = @grade_expander_template + %{</table>}
      @gxinfo = grade_expander_info
      render :action => 'show_instructor'
    elsif @assignment.course.is_student?(@user)
      # we show student view of assignment (default)
    else
      render :text => 'Forbidden.', :status => 403
    end
  end

  def new
    @assignment = Assignment.new
    @assignment.course = @assignment.course
  end

  def create
    @assignment = Assignment.new
    @assignment.course = @course
    @assignment.utc_starts_at = @course.semester.utc_starts_at
    if !params[:template].blank? && params[:template].to_i != 0
      template = @course.user.assignment_templates.find(params[:template])
      @assignment.copy_from_template(template) if !template.nil?
    end
    @assignment.save!
    redirect_to :action => :show, :id => @assignment
  end

  def edit
    if !@assignment.course.is_designer?(@user)
      render :text => 'Forbidden!', :status => :forbidden
    end
  end

  def update
    if @assignment.course.is_designer?(@user)
      if !params[:assignment][:author_eval].nil?
        author_eval = {
          :instructions => params[:assignment][:author_eval][:instructions],
          :prompts => hash_to_array(params[:assignment][:author_eval][:prompts])
        }

        author_eval[:prompts].each do |p|
          p[:responses] = hash_to_array(p[:responses])
        end

        params[:assignment][:author_eval] = author_eval
      end

      if !params[:assignment][:participant_eval].nil?
        participant_eval = {
          :instructions => params[:assignment][:participant_eval][:instructions],
          :prompts => hash_to_array(params[:assignment][:participant_eval][:prompts])
        }

        participant_eval[:prompts].each do |p|
          p[:responses] = hash_to_array(p[:responses])
        end

        params[:assignment][:participant_eval] = participant_eval
      end

      params[:assignment][:eval_duration] = params[:assignment][:eval_duration].to_i * 60 unless params[:assignment][:eval_duration].blank?;

      if(!params[:assignment]["starts_at(1i)"].blank?)
          params[:assignment][:starts_at] = DateTime.civil(
            params[:assignment]["starts_at(1i)"].to_i,
            params[:assignment]["starts_at(2i)"].to_i,
            params[:assignment]["starts_at(3i)"].to_i,
            params[:assignment]["starts_at(4i)"].to_i,
            params[:assignment]["starts_at(5i)"].to_i
          )
Rails.logger.info("starts at: #{YAML::dump(params[:assignment][:starts_at])}")
          params[:assignment][:utc_starts_at] = @assignment.course.tz.local_to_utc(params[:assignment][:starts_at]) #.to_formatted_s(:db)
          params[:assignment][:starts_at] = params[:assignment][:starts_at] #.to_formatted_s(:db)
          params[:assignment].delete("starts_at(1i)")
          params[:assignment].delete("starts_at(2i)")
          params[:assignment].delete("starts_at(3i)")
          params[:assignment].delete("starts_at(4i)")
          params[:assignment].delete("starts_at(5i)")
      end

      if @assignment.update_attributes(params[:assignment]) && @assignment.save
        redirect_to :action => :show, :id => @assignment
      else
        render :action => :edit, :id => @assignment
      end
      return
      respond_to do |format|
        format.ext_json { render :json => @assignment.to_ext_json(:success => @assignment.update_attributes(params[:assignment])) }
      end
    else
      respond_to do |format|
        format.ext_json { render :json => { :success => false } }
      end
    end
  end

protected

  def hash_to_array(h)
    r = [ ]
    h.keys.sort_by{|a,b| a.to_i <=> b.to_i}.each do |k|
      r << h[k]
    end
    return r
  end

  def find_assignment
    @assignment = Assignment.find(params[:id])
  end

  def find_course
    @course = Course.find(params[:course_id])
  end

  def require_assistant
    if @assignment.nil?
      @course.is_assistant?(@user)
    else
      @assignment.course.is_assistant?(@user)
    end
  end

  def require_instructor
    if @assignment.nil?
      @course.is_instructor?(@user)
    else
      @assignment.course.is_instructor?(@user)
    end
  end
end
