class GradesController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
      format.ext_json_html { render :json => ERB::Util::html_escape({ :success => false }.to_json), :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :show, :edit, :create ]

  def edit
    if !@assignment.course.is_assistant?(@user)
      render :text => 'Forbidden!', :status => :forbidden
    end
  end

  def create
    if !@assignment.course.is_assistant?(@user)
      render :text => 'Forbidden!', :status => :forbidden
    else
      params[:score].each_pair do |sub_id,score|
        next if score.blank?
        submission = (AssignmentSubmission.find(sub_id.to_i) rescue nil)
        next if submission.nil?
        next unless submission.assignment == @assignment
        submission.update_attribute(:instructor_score, score.to_f)
      end
      redirect_to :action => :edit
    end
  end

  def show
    if !@assignment.course.is_assistant?(@user)
      respond_to do |format|
        format.html { render :text => 'Forbidden!', :status => :forbidden }
        format.csv  { render :text => 'Forbidden!', :status => :forbidden }
        format.json { render :json => { :success => false }, :status => :forbidden }
        format.ext_json { render :json => { :success => false }, :status => :forbidden }
      end
    end

    @grades = [ ]
    @csv_columns = [:uin, :name]
    @csv_column_names = [ 'uin', 'name' ]
    
    if @assignment.is_ended? && !params[:format].blank? && params[:format] != 'html'
      @assignment.calculate_all_scores unless @assignment.scores_calculated?

      if params[:type].blank? || params[:type] == 'grades'
        params[:type] = 'grades'
        get_response_data(:grades)
      elsif params[:type] == "responses"
        get_response_data(:responses)
      else
        render :text => 'Forbidden!', :status => :forbidden
      end
    end

    respond_to do |format|
      format.html
      format.csv {
        out = ''
        CSV::Writer.generate(out) do |csv|
          csv.add_row @csv_column_names
          @grades.each do |g|
            csv.add_row @csv_columns.map{|c| g[c]}
          end
        end
        send_data(out,
          :type => 'text/csv; charset=utf-8; header=present',
          :filename => 'assignment-' + @assignment.position.to_s + '-' + params[:type] + '.csv'
        )
      }
      format.ext_json { render :json => { :results => @grades.length, :items => @grades } }
    end
  end

protected

  def get_response_data(rtype = :responses)
    @assignment.configured_modules(nil).each do |m|
      if !m.participant_rubric.nil?  && !m.author_name.blank?
        nm = m.tag + '_' + m.author_name.downcase + '_' 
        m.number_participants.times do |i|
          case rtype
            when :responses:
              m.participant_rubric.prompts.sort_by(&:position).each do |p|
                @csv_columns << nm + i.to_s + '_' + p.tag
                @csv_column_names << nm + (i+1).to_s + '_' + p.tag
              end
            when :grades:
              @csv_columns << nm + i.to_s
              @csv_column_names << nm + (i+1).to_s
          end
        end
        case rtype
          when :grades:
            @csv_columns << nm + 'avg'
            @csv_column_names << nm + 'avg'
        end
      end
      if !m.author_rubric.nil? && !m.participant_name.blank?
        nm = m.tag + '_' + m.participant_name.downcase + '_' 
        m.number_participants.times do |i|
          case rtype
            when :responses:
              m.author_rubric.prompts.sort_by(&:position).each do |p|
                @csv_columns << nm + i.to_s + '_' + p.tag
                @csv_column_names << nm + (i+1).to_s + '_' + p.tag
              end
            when :grades:
              @csv_columns << nm + i.to_s
              @csv_column_names << nm + (i+1).to_s
          end
        end
        case rtype
          when :grades:
            @csv_columns << nm + 'avg'
            @csv_column_names << nm + 'avg'
        end
      end
    end
    if @assignment.author_rubric
      nm = 'self_eval'
      case rtype
        when :responses:
          @assignment.author_rubric.prompts.sort_by(&:position).each do |p|
            @csv_columns << nm + '_' + p.tag
            @csv_column_names << nm + '_' + p.tag
          end
        when :grades:
          @csv_columns << nm
          @csv_column_names << nm
          @csv_columns << nm + '_var'
          @csv_column_names << nm + '_var'
      end
    end
    if @assignment.participant_rubric
      nm = @assignment.eval_tag
      case rtype
        when :grades:
          @assignment.number_evaluations.times do |i|
            @csv_columns << nm + '_' + (i+1).to_s + '_var'
            @csv_column_names << nm + '_' + (i+1).to_s + '_var'
          end
          @csv_columns << nm + '_var'
          @csv_column_names << nm + '_var'
          @csv_columns << nm + '_grade'
          @csv_column_names << nm + '_grade'
      end
    end

    if rtype == :grades
      @csv_columns << 'total_var'
      @csv_column_names << 'total_var'
      @csv_columns << :instructor
      @csv_column_names << 'instructor'
      @csv_columns << :final
      @csv_column_names << 'final'
      @csv_columns << :trust
      @csv_column_names << 'trust'
      if @assignment.participant_rubric
        nm = @assignment.eval_tag
        @assignment.number_evaluations.times do |i|
          @csv_columns << nm + '_' + (i+1).to_s + '_student'
          @csv_column_names << nm + '_' + (i+1).to_s + '_student'
          @csv_columns << nm + '_' + (i+1).to_s + '_instructor'
          @csv_column_names << nm + '_' + (i+1).to_s + '_instructor'
        end
      end
    end

    @assignment.course.course_participants.sort_by{|c| c.user.name || ''}.each do |cp|
      next unless cp.is_student?
      grade = {
        :id => cp.user.id,
        :name => cp.user.name,
        :uin => cp.user.uin,
      }

      push_grade = false
      if @assignment.is_participant?(cp.user)
        s = @assignment.assignment_submission(cp.user)
        # we want grades for each component...
        grade[:is_participant] = true
        @assignment.configured_modules(nil).each do |m|
          if m.has_evaluation?
            if !m.participant_rubric.nil?  && !m.author_name.blank?
              nm = m.tag + '_' + m.author_name.downcase + '_' 
              i = 0
              total = 0
              weight = 0
              s.participations_for(m,:author).each do |ap|
                e = ap.participant_eval
                if !e.nil? && !e.empty?
                  case rtype
                    when :responses:
                      m.participant_rubric.prompts.sort_by(&:position).each do |p|
                        grade[nm + i.to_s + '_' + p.tag] = e[p.tag] ||
                                                           e[p.position-1] ||
                                                           e[(p.position-1).to_s]
                      end
                    when :grades:
                      grade[nm+i.to_s] = round_score(ap.participant_eval_score)
                      total = total + ap.participant_eval_score
                      weight = weight + 1
                  end
                end
                i = i + 1
              end
              case rtype
                when :grades:
                  grade[nm+'avg'] = round_score(total / weight) if weight > 0
              end
            end
            if !m.author_rubric.nil?  && !m.participant_name.blank?
              nm = m.tag + '_' + m.participant_name.downcase + '_' 
              i = 0
              total = 0
              weight = 0
              s.participations_for(m,:participant).each do |ap|
                e = ap.author_eval
                if !e.nil? && !e.empty?
                  case rtype
                    when :responses:
                      m.author_rubric.prompts.sort_by(&:position).each do |p|
                        grade[nm + i.to_s + '_' + p.tag] = e[p.tag] ||
                                                           e[p.position-1] ||
                                                           e[(p.position-1).to_s]
                      end
                    when :grades:
                      grade[nm+i.to_s] = round_score(ap.author_eval_score)
                      total = total + ap.author_eval_score
                      weight = weight + 1
                  end
                end
                i = i + 1
              end
              case rtype
                when :grades:
                  grade[nm+'avg'] = round_score(total / weight) if weight > 0
              end
            end
          end
        end
        total_var = 0
        if @assignment.author_rubric
          e = s.author_eval
          nm = 'self_eval'
          if !e.nil? && !e.empty?
            case rtype
              when :responses:
                @assignment.author_rubric.prompts.sort_by(&:position).each do |p|
                  grade[nm + '_' + p.tag] = e[p.tag] || e[p.position-1] || e[(p.position-1).to_s]
                end
              when :grades:
                grade[nm] = round_score(s.author_eval_score)
                if s.instructor_score.blank?
                  grade[nm + '_var'] = '-'
                else
                  total_var = (s.author_eval_score - s.instructor_score).abs
                  grade[nm + '_var'] = round_score(total_var)
                end
            end
          end
        end
        if rtype == :grades
          grade[:final] = round_score(s.score)
          if s.trust.nil?
            grade[:trust] = '-'
          else
            grade[:trust] = round_score(s.trust*100.0)
          end

          # now get instructor grade info
          nm = @assignment.eval_tag + '_'
          if s.instructor_score.blank?
            grade[:instructor] = '-'
          else
            grade[:instructor] = round_score(s.instructor_score)
          end
          eval_var_t = 0
          eval_var_n = 0
          eval_grade = 0
          if @assignment.participant_rubric
            i = 1
            s.participations_for(@assignment.configured_modules(nil).last,:participant).each do |ap|
              if ap.assignment_submission.instructor_score.blank? || ap.participant_eval_score.blank?
                grade[nm+i.to_s+'_var'] = '-'
                if ap.assignment_submission.instructor_score.blank?
                  grade[nm+i.to_s+'_instructor'] = '-'
                else
                  grade[nm+i.to_s+'_instructor'] = round_score(ap.assignment_submission.instructor_score)
                end
                if ap.participant_eval_score.blank?
                  grade[nm+i.to_s+'_student'] = '-'
                else
                  grade[nm+i.to_s+'_student'] = round_score(ap.participant_eval_score)
                end
              else
                v = (ap.participant_eval_score - ap.assignment_submission.instructor_score).abs
                eval_grade = eval_grade + 33.4 - v * 0.534
                grade[nm + i.to_s + '_var'] = round_score(v)
                grade[nm + i.to_s + '_instructor'] = round_score(ap.assignment_submission.instructor_score)
                grade[nm+i.to_s + '_student'] = round_score(ap.participant_eval_score)
                eval_var_t = eval_var_t + v
                eval_var_n = eval_var_n + 1
              end
              i = i + 1
            end
            if eval_var_n > 0
              grade[nm+'var'] = round_score(eval_var_t / eval_var_n)
              total_var = total_var + eval_var_t / eval_var_n
            else
              grade[nm+'var'] = '-'
            end
            grade[nm+'grade'] = round_score(eval_grade)
          end
          grade['total_var'] = round_score(total_var)
        end
      else
        grade[:is_participant] = false
      end
      @grades << grade
    end
  end

  def find_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def round_score(s)
    if s.blank? || s == false
      '-'
    else
      (s * 100).round.to_f/100
    end
  end
end
