class AssignmentSubmissionsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
      format.ext_json_html { render :json => ERB::Util::html_escape({ :success => false }.to_json), :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :index ]

  def index
    if @assignment.course.is_assistant?(@user)
      respond_to do |format|
        format.html { prep_for_index_html }
        format.ext_json { prep_for_index_json
          render :json => { :results => @grades.length, :items => @grades } 
        }
      end
    elsif @assignment.course.is_student?(@user)
      # dump grades for the student
    else
      # nada
      respond_to do |format|
        format.html { render :text => 'Forbidden!', :status => :forbidden }
        format.json { render :json => { :success => false }, :status => :forbidden }
        format.ext_json { render :json => { :success => false }, :status => :forbidden }
      end
    end
  end

protected

  def prep_for_index_html
    @configured_modules_info = [ ]
    @performance_store_fields = [ 'id', 'name', 'is_participant', 'progress_info',  'messages_url' ]
    @performance_columns = [
      { :id => 'name', :dataIndex => 'name', :header => 'Name', :sortable => true }
    ]

    @assignment.configured_modules(nil).each do |m|
      if m.is_evaluative?
        if !m.author_name.blank?
          m.number_participants.times do |i|
            nm = 'author_' + m.position.to_s + '_' + i.to_s
            @performance_store_fields << nm
            @performance_columns << {
              :header => m.author_name + ' #' + (i+1).to_s,
              :dataIndex => nm,
              :sortable => true
            }
          end
        end
        if !m.participant_name.blank?
          m.number_participants.times do |i|
            nm = 'participant_' + m.position.to_s + '_' + i.to_s
            @performance_store_fields << nm
            @performance_columns << {
              :header => m.participant_name + ' #' + (i+1).to_s,
              :dataIndex => nm,
              :sortable => true
            }
          end
        end
      end
    end
  end

  def prep_for_index_json
    # dump all grades for all participants

    @grades = [ ]
    @assignment.course.course_participants.each do |student|
      next if student.level > 0
      submission = AssignmentSubmission.find(:first, :conditions => [
        'assignment_id = ? AND user_id = ?',
        @assignment.id, student.user.id ]) rescue nil

      grade = { :id => student.user.id, :name => student.user.name }
  
      if submission
        grade[:is_participant] = true
        grade[:progress_info] = submission.show_info(@assignment.current_module(nil) ? @assignment.current_module(nil).position + 1 : @assignment.configured_modules(nil).last.position + 1, @user)
        grade[:messages_url] = assignment_submission_messages_path(submission)

        @assignment.configured_modules(nil).each do |m|
          if m.is_evaluative?
            if !m.author_name.blank?
              i = 0
              AssignmentParticipation.find(:all,
                :joins => [ :assignment_submission ],
                :conditions => [
                  'assignment_submissions.assignment_id = ? AND
                   assignment_participations.tag = ? AND
                   assignment_participations.user_id = ?',
                  @assignment.id, m.tag, student.user.id
                ],
                :order => 'author_name').each do |ap|
                   grade[('author_' + m.position.to_s + '_' + i.to_s)] =
                     ap.assignment_submission.user.name
                   i = i + 1
              end
            end
            if !m.participant_name.blank?
              i = 0
              AssignmentParticipation.find(:all,
                :conditions => [
                  'assignment_submission_id = ? AND
                   tag = ?',
                  submission.id, m.tag
                ],
                :order => 'participant_name').each do |ap|
                  grade[('participant_' + m.position.to_s + '_' + i.to_s)] =
                    ap.user.name
                  i = i + 1
              end
            end
          end
        end
      else
        grade[:is_participant] = false
        grade[:progress_info] = '<p>No submission for this assignment.</p>'
      end
      @grades << grade
    end
  end

  def find_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end
end
