class MessagesController < ApplicationController
  def index
    @user = current_user

    @assignment_participations = [ ]
    @recipients = [ ]

    if !params[:assignment_id].blank?
      @assignment = Assignment.find(params[:assignment_id])

      if(!@assignment.course.is_student?(@user))
        render :text => 'Forbidden!', :status => 403
      end

    # we want the list of authors we are evaluating and 
    # the list of evaluators we are working with
    # for the current assignment module

      @current_module = @assignment.current_module(@user)
      @we_allow_new_messages = false
      if @current_module && @current_module.has_messaging?
        @we_allow_new_messages = true
        r = get_recipients(@current_module)
        @assignment_participations = r[0]
        @recipients = r[1]
      end
    else
      @assignment.configured_modules(@user).select{ |m| m.position <= @current_module.position && m.has_messaging? }.each do |m|
        r = get_recipients(m)
        @assignment_participations = @assignment_participations + r[0]
        @recipients = @recipients + r[1]
      end
    end

    respond_to do |format|
      format.html { render :layout => params[:embedded] ? false : 'application' }
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
        else
          @messages = [ ]
        end

        render :json => @messages.map { |m|
          h = { :id => m.id, 
                :subject => m.subject,
                :created_at => m.created_at.to_s,
              }
          if @user == m.user
            h[:is_read] = true
            h[:user] = "-"
            if m.assignment_participation.assignment_submission.user == @user
              h[:recipient] = m.assignment_participation.participant_name
            else
              h[:recipient] = m.assignment_participation.author_name
              h['recipient-portfolio'] = 'portfolio-' + m.assignment_participation.id.to_s
            end
          else
            h[:is_read] = m.is_read
            h[:recipient] = "-"
            if m.assignment_participation.assignment_submission.user == @user
              # evaluator sent the message (you're the author)
              h[:user] = m.assignment_participation.participant_name
              h['recipient-portfolio'] = 'own-portfolio'
            else
              # author sent the message (you're the evaluator)
              h[:user] = m.assignment_participation.author_name
              h['recipient-portfolio'] = 'portfolio-' + m.assignment_participation.id.to_s
            end
          end
          h
        }.reverse.to_ext_json(:class => Message)
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
    if @message.user == @user || 
       @message.assignment_participation.user == @user || 
       @message.assignment_participation.assignment_submission.user == @user

      @message.is_read = true
      @message.save

      respond_to do |format|
        format.html
      end

    else

      respond_to do |format|
        format.html :text => 'Forbidden!', :status => 403
      end

    end
  end

protected

  def get_recipients(m)
    recipients = [ ]
    ap = m.assignment_participations
    ap.sort_by(&:author_name).each do |p|
      recipients << [ p.id, p.author_name ]
    end
    AssignmentParticipation.find(:all,
      :joins => [ :assignment_submission ],
      :conditions => [
        'assignment_submissions.assignment_id = ? AND assignment_submissions.user_id = ? AND assignment_participations.tag = ?', @assignment.id, @user.id, m.tag ],
      :select => 'assignment_participations.*',
      :order => 'assignment_participations.participant_name'
    ).each do |p|
      recipients << [ p.id, p.participant_name ]
    end
    recipients = recipients.delete_if{ |e| e[0].nil? || e[1].nil? }
    return [ ap, recipients ]
  end
end
