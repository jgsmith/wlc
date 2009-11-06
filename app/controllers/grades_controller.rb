class GradesController < ApplicationController

  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
      format.ext_json_html { render :json => ERB::Util::html_escape({ :success => false }.to_json), :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :show ]

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
    @csv_columns = [:uin]
    @csv_column_names = [ 'uin' ]
    
    if @assignment.is_ended? && !params[:format].blank? && params[:format] != 'html'
      @assignment.calculate_all_scores unless @assignment.scores_calculated?

      if params[:type].blank? || params[:type] == 'grades'
        params[:type] = 'grades'
        get_grades
      elsif params[:type] == "responses"
        get_responses
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

  def get_responses
    @assignment.configured_modules(nil).each do |m|
      if !m.participant_rubric.nil?  && !m.author_name.blank?
        m.number_participants.times do |i|
          nm = m.tag + '_' + m.author_name.downcase + '_' 
          m.participant_rubric.prompts.each do |p|
            @csv_columns << nm + i.to_s + '_' + p.tag
            @csv_column_names << nm + (i+1).to_s + '_' + p.tag
          end
        end
      end
      if !m.author_rubric.nil? && !m.participant_name.blank?
        m.number_participants.times do |i|
          nm = m.tag + '_' + m.participant_name.downcase + '_' 
          m.author_rubric.prompts.each do |p|
            @csv_columns << nm + i.to_s + '_' + p.tag
            @csv_column_names << nm + (i+1).to_s + '_' + p.tag
          end
        end
      end
    end
    if @assignment.author_rubric
      nm = 'self_eval_'
      @assignment.author_rubric.prompts.each do |p|
        @csv_columns << nm + p.tag
        @csv_column_names << nm + p.tag
      end
    end

    @assignment.course.course_participants.each do |cp|
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
              s.participations_for(m,:author).each do |ap|
                e = ap.participant_eval
                if !e.nil? && !e.empty?
                  m.participant_rubric.prompts.each do |p|
                    grade[nm + i.to_s + '_' + p.tag] = e[p.tag] ||
                                                       e[p.position-1] ||
                                                       e[(p.position-1).to_s]
                  end
                end
                i = i + 1
              end
            end
            if !m.author_rubric.nil?  && !m.participant_name.blank?
              nm = m.tag + '_' + m.participant_name.downcase + '_' 
              i = 0
              s.participations_for(m,:participant).each do |ap|
                e = ap.author_eval
                if !e.nil? && !e.empty?
                  m.author_rubric.prompts.each do |p|
                    grade[nm + i.to_s + '_' + p.tag] = e[p.tag] ||
                                                       e[p.position-1] ||
                                                       e[(p.position-1).to_s]
                  end
                end
                i = i + 1
              end
            end
          end
        end
        if @assignment.author_rubric
          e = s.author_eval
          nm = 'self_eval_'
          if !e.nil? && !e.empty?
            @assignment.author_rubric.prompts.each do |p|
              grade[nm + p.tag] = e[p.tag] || e[p.position-1] || e[(p.position-1).to_s]
            end
          end
        end
      else
        grade[:is_participant] = false
      end
      @grades << grade
    end
  end

  def get_grades
    @assignment.configured_modules(nil).each do |m|
      if m.has_evaluation?
        if !m.participant_rubric.nil? && !m.author_name.blank?
          m.number_participants.times do |i|
            @csv_columns << 'participant_' + m.position.to_s + '_' + i.to_s
            @csv_column_names << m.tag + '_' + m.author_name.downcase + '_' + (i+1).to_s
          end
          @csv_columns << 'participant_' + m.position.to_s + '_avg'
          @csv_column_names << m.tag + '_' + m.author_name.downcase + '_avg'
        end
        if !m.author_rubric.nil? && !m.participant_name.blank?
          m.number_participants.times do |i|
            @csv_columns << 'author_' + m.position.to_s + '_' + i.to_s
            @csv_column_names << m.tag + '_' + m.participant_name.downcase + '_' + (i+1).to_s
          end
          @csv_columns << 'author_' + m.position.to_s + '_avg'
          @csv_column_names << m.tag + '_' + m.participant_name.downcase + '_avg'
        end
      end
    end
    if @assignment.author_rubric
      @csv_columns << :self_eval
      @csv_column_names << 'self_eval'
    end
    @csv_columns << :final
    @csv_columns << :is_participant
    @csv_column_names << 'final'
    @csv_column_names << 'is_participant'

    @assignment.course.course_participants.each do |cp|
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
            s_obj = @assignment.scores.first(:conditions => [
              'user_id = ? and tag = ?', cp.user.id, m.tag
            ])
            if m.participant_rubric && !m.author_name.blank?
              i = 0
              s.participations_for(m, :author).each do |ap|
                nm = 'author_' + m.position.to_s + '_' + i.to_s
                grade[nm] = ap.participant_eval ? (ap.participant_eval_score*100).round.to_f/100 : '-'
                grade[nm + '_name'] = ap.user.name
                i = i + 1
              end
              grade[('author_' + m.position.to_s + '_avg')] = (s_obj.participant_score*100).round.to_f/100 unless s_obj.participant_score.nil?
            end
            if m.author_rubric && !m.participant_name.blank?
              i = 0
              s.participations_for(m, :participant).each do |ap|
                nm = 'participant_' + m.position.to_s + '_' + i.to_s
                grade[nm] = ap.author_eval ? (ap.author_eval_score*100).round.to_f/100 : '-'
                grade[nm + '_name'] = ap.assignment_submission.user.name
                i = i + 1
              end
              grade[('participant_' + m.position.to_s + '_avg')] = (s_obj.author_score*100).round.to_f/100 unless s_obj.author_score.nil?
            end
          end
        end

        grade[:self_eval] = (s.author_eval_score*100).round.to_f/100
        grade[:final] = (s.score*100).round.to_f/100
        if s.trust.nil?
          grade[:trust] = '-'
        else
          grade[:trust] = (s.trust * 100.0 * 100).round.to_f/100
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
end
