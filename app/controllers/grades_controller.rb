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
        format.json { render :json => { :success => false }, :status => :forbidden }
        format.ext_json { render :json => { :success => false }, :status => :forbidden }
      end
    end

    @grades = [ ]
    
    if @assignment.is_ended?
      @assignment.calculate_all_scores unless @assignment.scores_calculated?
      @assignment.course.course_participants.each do |cp|
        next unless cp.is_student?
        grade = {
          :id => cp.user.id,
          :name => cp.user.name,
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
              if m.participant_rubric
                i = 0
                AssignmentParticipation.find(:all,
                  :joins => [ :assignment_submission ],
                  :conditions => [
                    'assignment_submissions.assignment_id = ? AND
                     assignment_participations.tag = ? AND
                     assignment_participations.user_id = ?',
                    @assignment.id, m.tag, cp.user.id
                  ],
                  :order => 'participant_name').each do |ap|
                     nm = 'participant_' + m.position.to_s + '_' + i.to_s
                     grade[nm] = ap.author_eval ? (ap.author_eval_score*100).round.to_f/100 : '-'
                     grade[nm + '_name'] = ap.assignment_submission.user.name
                     i = i + 1
                end
                grade[('participant_' + m.position.to_s + '_avg')] = (s_obj.participant_score*100).round.to_f/100 unless s_obj.participant_score.nil?
              end
              if m.author_rubric
                i = 0
                AssignmentParticipation.find(:all,
                  :conditions => [
                    'assignment_submission_id = ? AND
                     tag = ?',
                    s.id, m.tag
                  ],
                  :order => 'author_name').each do |ap|
                    nm = 'author_' + m.position.to_s + '_' + i.to_s
                    grade[nm] = ap.participant_eval ? (ap.participant_eval_score*100).round.to_f/100 : '-'
                     grade[nm + '_name'] = ap.user.name
                    i = i + 1
                end
                grade[('author_' + m.position.to_s + '_avg')] = (s_obj.author_score*100).round.to_f/100 unless s_obj.author_score.nil?
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
    respond_to do |format|
      #format.html
      format.ext_json { render :json => { :results => @grades.length, :items => @grades } }
    end
  end

protected

  def find_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end
end
