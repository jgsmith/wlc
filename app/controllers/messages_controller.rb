class MessagesController < ApplicationController
  def index
    @user = current_user

    if !params[:assignment_id].blank?
      @assignment = Assignment.find(params[:assignment_id])

      @recipients = [ ]
    # we want the list of authors we are evaluating and 
    # the list of evaluators we are working with
    # for the current assignment module

      @current_module = @assignment.current_module(@user)
      if @current_module
        @current_module.assignment_participations.sort_by(&:author_name).each do |p|
          @recipients << [ p.id, p.author_name ]
        end
        AssignmentParticipation.find(:all,
          :joins => [ :assignment_submission ],
          :conditions => [
            'assignment_submissions.assignment_id = ? AND assignment_submissions.user_id = ?', @assignment.id, @user.id ],
          :select => 'assignment_participations.id',
          :order => 'assignment_participations.participant_name'
        ).each do |p|
          @recipients << [ p.id, p.participant_name ]
        end
        @recipients = @recipients.delete_if{ |e| e[0].nil? || e[1].nil? }
      end
    end

    respond_to do |format|
      format.html
      format.ext_json do
        if !params[:assignment_participation_id].blank?
          @messages = Message.find(:all,
            :joins => [ :assignment_participations ],
            :conditions => [
              'assignment_participations.id = ? AND assignment_participations.user_id = ?',
              params[:assignment_participation_id].to_i, @user.id
            ],
            :order => 'id'
          )
        elsif !params[:assignment_id].blank?
          @assignment = Assignment.find(params[:assignment_id])
          # we want all of the messages for this user's assignment submission
          # if we're done with the assignment
          # we want all the messages to/from this user for this assignment
    
          @messages = Message.find_by_sql(["
            SELECT DISTINCT m.* 
            FROM messages m
            LEFT JOIN assignment_participations a_p 
                   ON a_p.id = m.assignment_participation_id
            LEFT JOIN assignment_submissions a_s
                   ON a_s.id = a_p.assignment_submission_id
            WHERE (a_s.user_id = ? OR a_p.user_id = ?) AND a_s.assignment_id = ?
            ORDER BY m.id
          ", @user.id, @user.id, @assignment.id])
          
    #      @messages = Message.find(:all,
    #        :joins => 'LEFT JOIN assignment_participations ON assignment_participations.id = messages.assignment_participation_id LEFT JOIN assignment_submissions ON assignment_submissions.id = assignment_participations.assignment_submission_id',
    ##[ :assignment_participations, :assignment_submissions ],
    #        :select => 'messages.*',
    #        :conditions => [
    #          'assignment_submissions.assignment_id = ? AND (assignment_submissions.user_id = ? OR assignment_participations.user_id = ?)',
    #          params[:assignment_id].to_i, @user.id
    #        ],
    #        :order => 'id'
    #      )
        else
          @messages = [ ]
        end

        render :json => @messages.map { |m|
          h = { :id => m.id, 
                :subject => m.subject,
                :created_at => m.created_at,
              }
          if @user == m.user
            h[:is_read] = true
            h[:user] = "-"
          else
            h[:is_read] = m.is_read
            if m.assignment_participation.assignment_submission.user == @user
              # evaluator sent the message (you're the author)
              h[:user] = m.assignment_participation.name
            else
              # author sent the message (you're the evaluator)
            h[:user] = m.assignment_participation.author_name
              end
            end
            h
          }.to_ext_json(:class => Message)
      end
    end
  end

  def create
    @user = current_user
    @assignment = Assignment.find(params[:assignment_id])
    @assignment_participation = AssignmentParticipation.find(params[:assignment_participation_id])
    if @assignment_participation.assignment_submission.assignment == @assignment &&
       (@assignment_participation.user == @user || @assignment_participation.assignment_submission.user == @user)
      @message = Message.create(
        :user => @user,
        :assignment_participation => @assignment_participation,
        :subject => params[:subject],
        :content => params[:content]
      );

      respond_to do |format|
        format.html
        format.ext_json { render :json => { :success => true } }
        format.ext_json_html { render :json => ERB::Utils::html_escape( { :success => true }.to_json) }
      end
    else
      respond_to do |format|
        format.html
        format.ext_json { render :json => { :success => false } }
        format.ext_json_html { render :json => ERB::Utils::html_escape( { :success => false }.to_json) }
      end
    end
  end

  def show
    @message = Message.find(params[:id])
    @user = current_user
    if @message.user == @user || @message.assignment_participation.user == @user || @message.assignment_participation.assignment_submission.user == @user
      respond_to do |format|
        format.html
      end
    else
      respond_to do |format|
        format.html :text => 'Forbidden!', :status => 403
      end
    end
  end
end
