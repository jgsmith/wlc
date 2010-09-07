class ConfiguredModule
  attr_accessor :module_def, :utc_starts_at
  attr_writer   :instructions, :name
  attr_accessor :user, :duration, :position, :number_participants
  attr_accessor :participant_eval, :author_eval, :has_messaging
  attr_accessor :assignment, :author_name, :participant_name
  attr_accessor :is_evaluation, :tag
  attr_accessor :download_filename_prefix
  attr_accessor :params
  attr_accessor :author_rubric, :participant_rubric

  def instructions
    @instructions = module_def.instructions if !module_def.nil? && !defined? @instructions
    @instructions
  end

  def name
    if !defined? @name
      if module_def.nil?
        @name = 'Unamed Step'
      else
        @name = module_def.name
      end
    end
    @name
  end

  def context
    if module_def.nil?
      Fabulator::Expr::Context.new
    else
      module_def.context
    end
  end

  def is_evaluative?
    return false if self.has_messaging
    return false if self.module_def.nil?
    return self.module_def.is_evaluative?
  end

  #
  # The UTC time at which the module ends.
  #
  def utc_ends_at
    self.utc_starts_at + self.duration.to_i
  end

  #
  # ConfigureModule#utc_ends_at adjusted to the Course#tz.
  #
  def ends_at
    self.assignment.course.tz.utc_to_local(self.utc_ends_at)
  end

  #
  # ConfigureModule#utc_starts_at adjusted to the Course#tz.
  #
  def starts_at
    self.assignment.course.tz.utc_to_local(self.utc_starts_at)
  end

  #
  # True if the module is purely informational.  Informational modules
  # have nothing with which students can interact.
  #
  def informational?
    self.module_def.nil? && !self.has_messaging? && !self.is_evaluation
  end

  #
  # True if the module has private messaging.  Private messaging requires
  # the module have a ConfiguredModule#participant_name and
  # ConfiguredModule#author_name configured.
  #
  def has_messaging?
    !!self.has_messaging && !self.participant_name.blank? && !self.author_name.blank?
  end

  #
  # True if a rubric is attached to this module.
  #
  def has_evaluation?
    !self.author_eval.nil? && !self.author_eval.empty? || 
    !self.participant_eval.nil? && !self.participant_eval.empty?
  end

  #
  # Merges the given AssignmentModule or AssignmentTemplateModule
  # configuration with the object's current configuration.  This is
  # a shallow merge, so, for example, #params keys are not merged, but
  # the entire Hash is replaced.
  #
  def apply_module(am)
    self.instructions = am.instructions unless am.instructions.nil?
    self.name         = am.name         unless am.name.nil?
    self.number_participants = am.number_participants
    self.has_messaging = am.has_messaging
    self.participant_name = am.participant_name unless am.participant_name.blank?
    self.author_name = am.author_name unless am.author_name.blank?
    self.author_eval  = am.author_eval  unless am.author_eval.nil?
    self.participant_eval = am.participant_eval unless am.participant_eval.nil?
    self.author_rubric = am.author_rubric unless am.author_rubric.nil?
    self.participant_rubric = am.participant_rubric unless am.participant_rubric.nil?
    self.duration     = am.duration     unless am.duration.nil?
    self.position     = am.position     unless self.position
    self.download_filename_prefix = am.download_filename_prefix unless am.download_filename_prefix.blank?
    self.tag          = am.tag          unless am.tag.blank?
    self.params       = am.params       unless am.params.nil?
  end

  #
  # The AssignmentSubmission for the ConfiguredModule#assignment and
  # ConfiguredModule#user, or nil if none exists
  def assignment_submission
     return nil if self.user.nil? || self.assignment.nil?
     AssignmentSubmission.find(:first, :conditions => [
       'user_id = ? AND assignment_id = ?',
       self.user.id, self.assignment.id
     ])
  end

  #
  # True if there are messages associated with this module and the
  # ConfiguredModule#user (either sent or recieved by the user).
  #
  def has_messages?
    # if the user has sent any or received any, then we return true
    0 < Message.count_by_sql(%{
        SELECT COUNT(*)
        FROM messages m
        LEFT JOIN assignment_participations a_p
                  ON a_p.id = m.assignment_participation_id
        LEFT JOIN assignment_submissions a_s
                  ON a_s.id = a_p.assignment_submission_id
        WHERE (a_s.user_id = #{@user.id} OR a_p.user_id = #{@user.id}) AND a_s.assignment_id = #{@assignment.id}
    }) #, @user.id, @user.id, @assignment.id])
  end

  #
  # Returns a list of AssignmentParticipation objects for this
  # module and the ConfiguredModule#user.
  #
  # If this is the first module in an assignment, then an unsaved
  # AssignmentParticipation is returned if the student has not already
  # submitted data establishing participation in the assignment.
  #
  # If the existing AssignmentParticipation objects are not sufficient
  # to satisfy the number needed by ConfiguredModule#number_participants,
  # then random assignments are made beginning with students who have the
  # fewest number of participants assigned to them.
  #
  def assignment_participations(override_timing = false)
    # this is where we assign participations if we need to
    # this is from the self.user's pov
    return [ ] if self.assignment.nil?

    if self.user.nil?
      # build a preview version of the participation
      p = AssignmentParticipation.new
      p.configured_module = self
      p.assignment = @assignment
      p.tag = self.tag
      p.initialize_participation
      return [ p ]
    end

    @assignment_participations ||= AssignmentParticipation.find(:all, 
      :joins => [ :assignment_submission ],
      :select => 'assignment_participations.*',
      :conditions => [
        'assignment_submissions.assignment_id = ? AND 
         assignment_participations.tag    = ? AND
         assignment_participations.user_id     = ?',
        self.assignment.id, self.tag, self.user.id
      ])

    ## don't assign any participations if we aren't the current module
    if !override_timing && (self.starts_at > assignment.course.now || assignment.course.now > self.ends_at)
      return @assignment_participations
    end

    if self.position == 1
      if @assignment_participations.size == 0
        p = AssignmentParticipation.new
        p.configured_module = self
        p.assignment = @assignment
        p.tag = self.tag
        p.initialize_participation
        @assignment_participations = [ p ]
      end
    elsif @assignment_participations.size < self.number_participants
      raise WLC::ReloadPage
    end
    return @assignment_participations
  end

  def make_participation_assignments
    return if self.user.nil?

    @assignment_participations ||= AssignmentParticipation.find(:all, 
      :joins => [ :assignment_submission ],
      :select => 'assignment_participations.*',
      :conditions => [
        'assignment_submissions.assignment_id = ? AND 
         assignment_participations.tag    = ? AND
         assignment_participations.user_id     = ?',
        self.assignment.id, self.tag, self.user.id
      ])

    s = AssignmentSubmission.first :conditions => [
      'assignment_id = ? AND user_id = ?',
      self.assignment.id, self.user.id
    ]
    if self.assignment.is_participant?(self.user)

      if self.module_def.nil? && self.has_messaging? ||
         !self.module_def.nil? && self.module_def.is_evaluative? ||
         self.is_evaluation

        submissions = available_participants(self.user)

        while submissions.size > 0 && 
              @assignment_participations.size < self.number_participants
          
          c = submissions.shift
          if defined? c
            p = nil
            AssignmentParticipation.transaction do
              p = AssignmentParticipation.create(
                :assignment_submission => c,
                :user => self.user,
                :tag => self.tag
              )
              if self.has_messaging? || self.has_evaluation?
                p.author_name = self.author_name + ' #' + (@assignment_participations.size+1).to_s unless self.author_name.blank?
                p.participant_name = self.participant_name + ' #' + (c.assignment_participations.select{ |ap| ap.tag == self.tag }.size + 1).to_s unless self.participant_name.blank?
              end
              p.initialize_participation
              p.save
              # make sure we don't have too many participations for the submission
              if p.assignment_submission.assignment_participations.select{ |ap| ap.tag == self.tag }.size > self.number_participants
                raise ActiveRecord::Rollback
              end
              @assignment_participations << p
            end 
          end
        end
      elsif @assignment_participations.empty? 
        p = AssignmentParticipation.create(
          :user => self.user,
          :assignment_submission => s,
          :tag => self.tag
        )
        p.initialize_participation
        p.save
        @assignment_participations << p
      end
    end
  end

  #
  # Returns a list of AssignmentSubmission objects for the 
  # ConfiguredModule#assignment who do not have sufficient participants
  # assigned for this module.
  #
  def available_participants(u)
    available = self.assignment.assignment_submissions.select{|a|
      u.nil? ||
      a.user != self.user &&
      AssignmentParticipation.count(:conditions => [  
        'assignment_submission_id = ? AND user_id = ?',
        a.id, self.user.id
      ]) == 0
    }.group_by{|a|
      a.assignment_participations.count
    }
    submissions = [ ]
    available.keys.sort.each do |k|
      submissions = submissions + available[k].sort_by { rand }
    end
    submissions.uniq!
    submissions.select{ |s| s.assignment_participations.select{ |ap| ap.tag == self.tag }.size < self.number_participants }
  end

  def save_score(as, t, s)
    Rails.logger.info("#{self.assignment_module.id rescue '-'}.save_score(#{as.id}, #{t.to_s}, #{s})")
  end
end
