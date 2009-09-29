class AssignmentParticipantsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_to do |format|
      format.json { render :json => { :success => false }, :status => :not_found }
      format.ext_json { render :json => { :success => false }, :status => :not_found }
      format.ext_json_html { render :json => ERB::Util::html_escape({ :success => false }.to_json), :status => :not_found }
    end
  end

  before_filter :find_assignment, :only => [ :show ]

  def show
    @user = current_user
    if @user == @assignment.course.user
      # dump all grades for all participants
      @grades = [ ]
      @assignment.course.course_participants.each do |student|
        submission = AssignmentSubmission.find(:first, :conditions => [
          'assignment_id = ? AND user_id = ?',
          @assignment.id, student.user.id ]) rescue nil

        grade = [ student.user.id, student.user.name ]
        
        if submission
          @assignment.configured_modules(nil).each do |m|
            if m.has_evaluation?
              if !m.author_name.blank?
                g = [ ]
                AssignmentParticipations.find(:all,
                  :joins => [ :assignment_submissions ],
                  :conditions => [
                    'assignment_submissions.assignment_id = ? AND
                     assignment_participations.tag = ? AND
                     assignment_participations.user_id = ?',
                    @assignment.id, m.tag, student.user.id
                  ]).each do |ap|
                    g << ap.assignment_submission.user.name
                  end
                g << '' while g.length < m.number_participants
                grade = grade + g
              end
              if !m.participant_name.blank?
                g = [ ]
                AssignmentParticipations.find(:all,
                  :conditions => [
                    'assignment_submission_id = ? AND
                     tag = ?',
                    submission.id, m.tag
                  ]).each do |ap|
                    g << ap.user.name
                  end
                g << '' while g.length < m.number_participants
                grade = grade + g
              end
            end
          end
        else
          @assignment.configured_modules(@user).each do |m|
        
            if m.has_evaluation?
              if !m.author_name.blank?
                m.number_participants.times do |i|
                  grade << ''
                end
              end
              if !m.participant_name.blank?
                m.number_participants.times do |i|
                  grade << ''
                end
              end
            end
          end
        end
        @grades << grade
      end
      respond_to do |format|
        format.ext_json { render :json => { :results => @grades.length, :items => @grades } }
      end
    elsif @assignment.is_student?(@user)
      # dump grades for the student
    else
      # nada
      respond_to do |foramt|
        format.html { render :text => 'Forbidden!', :status => :forbidden }
        format.json { render :json => { :success => false }, :status => :forbidden }
        format.ext_json { render :json => { :success => false }, :status => :forbidden }
      end
    end
  end

protected

  def find_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end
end
