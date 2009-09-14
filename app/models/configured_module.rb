class ConfiguredModule
  attr_accessor :module_def, :utc_starts_at
  attr_writer   :instructions, :name
  attr_accessor :user, :duration, :position, :number_participants
  attr_accessor :participant_eval, :author_eval, :has_messaging
  attr_accessor :assignment, :author_name, :participant_name
  attr_accessor :is_evaluation, :tag
  attr_accessor :download_filename_prefix

  def instructions
    @instructions = module_def.instructions unless defined? @instructions
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

  def utc_ends_at
    self.utc_starts_at + self.duration.to_i
  end

  def ends_at
    self.assignment.course.tz.utc_to_local(self.utc_ends_at)
  end

  def starts_at
    self.assignment.course.tz.utc_to_local(self.utc_starts_at)
  end

  def informational?
    self.module_def.nil? && !self.has_messaging? && !self.is_evaluation
  end

  def has_messaging?
    !!self.has_messaging && !self.participant_name.blank? && !self.author_name.blank?
  end

  def has_evaluation?
    !self.author_eval.nil? && !self.author_eval.empty? || 
    !self.participant_eval.nil? && !self.participant_eval.empty?
  end

  def apply_module(am)
    self.instructions = am.instructions unless am.instructions.nil?
    self.name         = am.name         unless am.name.nil?
    self.number_participants = am.number_participants
    self.has_messaging = am.has_messaging
    self.participant_name = am.participant_name unless am.participant_name.blank?
    self.author_name = am.author_name unless am.author_name.blank?
    self.author_eval  = am.author_eval  unless am.author_eval.nil?
    self.participant_eval = am.participant_eval unless am.participant_eval.nil?
    self.duration     = am.duration     unless am.duration.nil?
    self.position     = am.position     unless self.position
    self.download_filename_prefix = am.download_filename_prefix unless am.download_filename_prefix.blank?
    self.tag          = am.tag          unless am.tag.blank?
  end

  def assignment_submission
     return nil if self.user.nil? || self.assignment.nil?
     AssignmentSubmission.find(:first, :conditions => [
       'user_id = ? AND assignment_id = ?',
       self.user.id, self.assignment.id
     ])
  end

  def assignment_participations
    # this is where we assign participations if we need to
    # this is from the self.user's pov
    return [ ] if self.assignment.nil? || self.user.nil?

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
    if self.starts_at > assignment.course.now || assignment.course.now > self.ends_at
      return @assignment_participations
    end

    if self.position == 1
      if @assignment_participations.size == 0
        p = AssignmentParticipation.new
        p.configured_module = self
        p.tag = self.tag
        p.initialize_participation
        @assignment_participations = [ p ]
      end
    elsif @assignment_participations.size < self.number_participants
      s = AssignmentSubmission.first :conditions => [
        'assignment_id = ? AND user_id = ?',
        self.assignment.id, self.user.id
      ]
      if defined? s  # did the user submit anything to the assignment?

        if self.module_def.nil? && self.has_messaging? ||
           !self.module_def.nil? && self.module_def.is_evaluative? ||
           self.is_evaluation

          available = self.assignment.assignment_submissions.select{|a|
            a.user != self.user &&
            AssignmentParticipation.count(:conditions => [
               'assignment_submission_id = ? AND user_id = ?',
               a.id, self.user.id
            ]) == 0
            #a.assignment_participations.select{|p| p.user==self.user}.size == 0
          }.group_by{|a|
            a.assignment_participations.count
          }
          submissions = [ ]
          available.keys.sort.each do |k|
            submissions << available[k].sort_by { rand }
          end
          submissions.flatten!
          submissions.uniq!

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
                  p.author_name = self.author_name + ' #' + (@assignment_participations.size+1).to_s
                  p.participant_name = self.participant_name + ' #' + (c.assignment_participations.count).to_s
                end
                p.initialize_participation
                p.save
              end 
              @assignment_participations << p unless p.nil?
            end
          end
        else
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

    return @assignment_participations
  end
end
