class Assignment < ActiveRecord::Base

  belongs_to :course

  belongs_to :author_rubric, :class_name => 'Rubric'
  belongs_to :participant_rubric, :class_name => 'Rubric'

  has_many :assignment_modules, :order => 'position'
  has_many :assignment_submissions, :order => 'id'
  has_many :scores, :dependent => :delete_all

  acts_as_list :scope => :course_id

  validates_each :utc_starts_at do |record, attr, value|
    record.errors.add "Assignment must start in the course's semester." if
      value < record.course.semester.utc_starts_at ||
      value > record.course.semester.utc_ends_at
  end

  validates_associated :assignment_modules

  serialize :old_participant_eval
  serialize :old_author_eval

  #
  # Returns a Hash representing the instructions and prompts for the
  # participant evaluation of the author.  This evaluation is done
  # at the end of the assignment and is intended as a review of the
  # entire assignment.  See Rubric#to_h.
  #
  def participant_eval
    if participant_rubric
      participant_rubric.to_h
    else
      old_participant_eval || {}
    end
  end

  #
  # Returns a Hash representing the instructions and prompts for the
  # author's self-evaluation.  This evaluation is done at the end of
  # the assignment and is intended as a review of the entire assignment.
  # See Rubric#to_h.
  #
  def author_eval
    if author_rubric
      author_rubric.to_h
    else
      old_author_eval || {}
    end
  end

  def starts_at
    self.course.tz.utc_to_local(self.utc_starts_at)
  end

  def starts_at=(t)
    self.utc_starts_at = self.course.tz.local_to_utc(t)
  end

  def ends_at
    self.course.tz.utc_to_local(self.utc_ends_at)
  end

  def is_ended?
    self.ends_at < self.course.now
  end

  def assignment_submission(user)
    AssignmentSubmission.first(:conditions => [
      'assignment_id = ? AND user_id = ?',
      self.id, user.id
    ]);
  end

  def is_participant?(user)
    !self.assignment_submission(user).nil?
  end

  def not_participating
    User.find(:all,
      :select => 'DISTINCT users.*',
      :joins => %{
        LEFT JOIN course_participants cp ON cp.user_id = users.id AND cp.level = 0
        LEFT JOIN courses c ON c.id = cp.course_id
        LEFT JOIN assignments a ON a.course_id = c.id
        LEFT OUTER JOIN assignment_submissions a_s ON cp.user_id = a_s.user_id
          AND a_s.assignment_id = a.id
      },
      :conditions => [
        'a.id = ? AND a_s.id IS NULL',
        self.id
      ],
      :order => 'users.name'
    )
  end

  def can_accept_late_work?
    return false unless self.late_work_acceptable?

    ## if we're past the second module, too late
    return false if self.current_module(nil).nil?

    # if we're past the second non-informational module, then it's too late
    # the initial submission module counts in this
    cur_pos = self.current_module(nil).position
    modules = self.configured_modules(nil).select { |m| !m.informational? && m.position <= cur_pos }

    return false if modules.size > 2

    ## if we have enough people left who haven't been assigned participations
    ## in the second module, then we can accept late work
    pool = self.current_module(nil).available_participants
    return false unless pool.size > self.current_module(nil).number_participants + 1

    return true
  end

  def has_messaging?(user)
    return false if self.current_module(user).nil?
    self.configured_modules(user).each do |m|
      break if m.position >= self.current_module(user).position
      return true if m.has_messaging?
    end
    return false
  end

  def configured_modules(user)
    if !defined? @configured_modules
      m_list = [ ]
      self.assignment_modules.each do |am|
          m_list[am.position] = am.configured_module(user)
      end

      @configured_modules = m_list.select{ |m| !m.nil? }

      cur_time = self.utc_starts_at
      @configured_modules.each do |m|
        m.utc_starts_at = cur_time
        cur_time += m.duration.to_i
        m.assignment = self
        m.is_evaluation = false
      end

      if @configured_modules.select{ |cm| cm.has_evaluation? }.size > 0 ||
         !self.participant_eval.nil? && !self.participant_eval.empty?   ||
         !self.author_eval.nil? && !self.author_eval.empty? 
        m = ConfiguredModule.new
        m.utc_starts_at = @configured_modules.last.utc_ends_at
        m.tag = self.eval_tag
        m.position = @configured_modules.last.position + 1
        m.is_evaluation = true
        m.user = user
        m.assignment = self
        m.instructions = ''
        m.name = self.eval_name || 'Evaluation'
        m.duration = self.eval_duration  || 0
        m.author_name = self.author_name unless self.author_name.blank?
        m.participant_eval = self.participant_eval unless self.participant_eval.nil?
        m.author_eval = self.author_eval unless self.author_eval.nil?
        m.participant_rubric = self.participant_rubric unless self.participant_rubric.nil?
        m.author_rubric = self.author_rubric unless self.author_rubric.nil?
        m.number_participants = self.number_evaluations unless self.number_evaluations < 1
        if m.participant_rubric.nil?
          m.number_participants = 0
        end
        @configured_modules << m
      end
    end

    return @configured_modules
  end

  def has_evaluations?(u)
    self.configured_modules(u).select{ |cm| cm.has_evaluation? }.size > 0
  end

  def current_module(user)
    if !defined? @current_module
      n = self.course.now
      configured_modules(user).reverse.each do |c|
        return c if c.starts_at <= n && c.ends_at >= n
      end
      #@current_module = configured_modules(user).select{|c| c.starts_at <= n}.sort_by(&:starts_at).last
      return nil
    end

    return nil if @current_module.ends_at < self.course.now

    return @current_module
  end

  def utc_ends_at
    @utc_ends_at ||= self.configured_modules(nil).last.utc_ends_at
    @utc_ends_at
  end

  def view_scores(u)
    return '' if self.score_view.blank?
    as = AssignmentSubmission.first(:conditions => [
      'user_id = ? AND assignment_id = ?',
      u.id, self.id
    ])

    return as.view_scores
  end

  def to_liquid
    d = AssignmentDrop.new
    d.assignment = self
    d
  end

  def needs_trust?
    self.configured_modules(nil).each do |cm|
      return true if cm.author_rubric && cm.author_rubric.use_trust? ||
                     cm.participant_rubric && cm.participant_rubric.use_trust? 
    end
    return false
  end

  def calculate_all_scores
    self.calculate_scores
    self.calculate_trust_scores if self.calculate_trust? || self.needs_trust?
    self.calculate_composite_scores
    self.update_attribute( :scores_calculated, true )
  end

  def calculate_scores
    modules = { }
    self.configured_modules(nil).each do |m|
      modules[m.tag] = m
    end
    self.assignment_submissions.each do |s|
      s.assignment_participations.each do |ap|
        if modules[ap.tag].author_rubric && ap.author_eval
          ap.author_eval_score = modules[ap.tag].author_rubric.calculate_score(ap.author_eval)
        end
        if modules[ap.tag].participant_rubric && ap.participant_eval
          ap.participant_eval_score = modules[ap.tag].participant_rubric.calculate_score(ap.participant_eval)
        end
        ap.save
      end
      if self.author_rubric
        s.author_eval_score = self.author_rubric.calculate_score(s.author_eval)
        s.save
      end
    end
  end

  #
  # Calculates the composite scores for an assignment if the assignment 
  # is ended.
  #
  def calculate_composite_scores
    self.scores.clear
    self.assignment_submissions.each do |s|
      # we want grades for each component...
      self.configured_modules(nil).each do |m|
        if m.has_evaluation?
          s_obj = self.scores.build({
            :user => s.user,
            :tag => m.tag
          })
            
          if m.author_rubric
            weight = 0.0
            score = 0.0
            AssignmentParticipation.find(:all,
              :joins => [ :assignment_submission ],
              :conditions => [
                'assignment_submissions.assignment_id = ? AND
                 assignment_participations.tag = ? AND
                 assignment_participations.user_id = ?',
                self.id, m.tag, s.user.id
              ]).each do |ap|
                 if ap.author_eval
                   if m.author_rubric.use_trust?
                     w = ap.assignment_submission.trust
                   else
                     w = 1.0
                   end
                   weight = weight + w
                   score = score + w*ap.author_eval_score
                 end
            end
            if weight > 0.0
              s_obj.participant_score = score / weight
            end
          end
          if m.participant_rubric
            weight = 0.0
            score = 0.0
            AssignmentParticipation.find(:all,
              :conditions => [
                'assignment_submission_id = ? AND
                 tag = ?',
                s.id, m.tag
              ]).each do |ap|
                if ap.participant_eval
                  if m.participant_rubric.use_trust?
                    w = self.assignment_submission(ap.user).trust
                  else
                    w = 1.0
                  end
                  weight = weight + w
                  score = score + w*ap.participant_eval_score
                end
            end
            if weight > 0.0
              s_obj.author_score = score / weight
            end
          end
          s_obj.save
        end
      end
      # now calculate final scores
      s.calculate_score(self.use_trust?)
    end
  end   

  #
  # Calculates the trust scores for this assignment.  For information
  # on the math behind the calculation, see the
  # {Wikipedia article on Eigenvector Centrality}[http://en.wikipedia.org/wiki/Eigenvector_centrality#Eigenvector_centrality].
  # 
  # Trust scores are stored in each student's AssignmentSubmission associated
  # with this Assignment.  Scores are renormalized so that the maximum score
  # is 1.0.
  #
  # The adjacency matrix represents how close an arbitrary pair of students
  # are with respect to their critical evaluation of the assignment.
  # A student is considered to have no relationship with themselves.
  #
  # Two students with similar trust scores should grade the same assignment
  # similarly.  A student with a higher trust score than another student
  # should grade the same assignment more accurately.
  #
  # N.B.: The eigenvector is normalized to have a length of 1.0 before we
  # renormalize it to have a maximum component of 1.0.  Thus, the values
  # represent relative trust levels and are not comparable across
  # assignments except to suggest that a student might be improving compared
  # to the average student in the course.
  #
  def calculate_trust_scores
    # we need to collect all of the rubric grades
    #   find out how many students participated in the assignment
    #   create adjacency matrix

    scorings = { }
    @submissions_used_in_trust = [ ]

    self.assignment_submissions.each do |as|
      as_used = false
      aps = as.assignment_participations.select{ |ap| ap.tag == self.eval_tag }
      aps.each do |ap1|
        next if !ap1.participant_eval || !ap1.participant_eval_score
        aps.each do |ap2|
          next if ap1 == ap2 || !ap2.participant_eval || !ap2.participant_eval_score
          n1 = "#{ap1.user.id}:#{ap2.user.id}"
          n2 = "#{ap2.user.id}:#{ap2.user.id}"
          scorings[n1] ||= [ ]
          scorings[n1] << self.calculate_similarity(ap1.participant_eval_score, ap2.participant_eval_score)
          scorings[n2] ||= [ ]
          scorings[n2] << self.calculate_similarity(ap1.participant_eval_score, ap2.participant_eval_score)
          as_used = true
        end

        if as.author_eval_score
          n = "#{as.user.id}:{ap1.user.id}"
          scorings[n] ||= [ ]
          scorings[n] << self.calculate_similarity(as.author_eval_score || 0, ap1.participant_eval_score)
          as_used = true
        end
      end
      @submissions_used_in_trust << as if as_used
    end

    self.assignment_submissions.each do |as|
      as.update_attribute(:trust, 0) unless @submissions_used_in_trust.include?(as)
    end

      submissions = @submissions_used_in_trust
      #submissions.each do |i|
      #  submissions.each do |j|
      #    graph.remove_edge(i,j)
      #    graph.remove_edge(j,i)
      #  end
      #  graph.remove_vertex(i)
      #end
      #vertices = graph.vertices
      num_students = submissions.size
      pair_wise = GSL::Matrix.zeros(num_students)
      num_students.times do |i|
        num_students.times do |j|
          next if i >= j

          user_i = submissions[i].user.id
          user_j = submissions[j].user.id
          res = [ ]
          res = res + scorings["#{user_i}:#{user_j}"] if scorings["#{user_i}:#{user_j}"]
          res = res + scorings["#{user_j}:#{user_i}"] if scorings["#{user_j}:#{user_i}"]

          # now do mean and store in matrix
          if !res.nil? && !res.empty?
            total = 0.0
            if self.trust_mean.nil? || self.trust_mean == 0
              # arithmetic mean
              res.each do |r|
                total = total + r
              end
              total = total / res.length
            elsif self.trust_mean == 1 && res.collect{|r| r <= 0.0}.size == 0
          
              res.each do |r|
                total = total + Math.log(r)
              end
              total = Math.exp(total / res.length)
            elsif res.collect{|r| r == 0.0}.size == 0
              total2 = 1.0
              res.each do |r|
                total = total + r
                total2 = total2 * r
              end
              total = res.length * total2 / total unless total == 0.0
            end
            pair_wise[i,j] = total
            pair_wise[j,i] = total
          end
        end
      end
      Rails.logger.info(pair_wise)
      Rails.logger.info("Max: #{pair_wise.max}   Min: #{pair_wise.min}")
      Rails.logger.info("Norm: #{pair_wise.norm}")
      Rails.logger.info("Trace: #{pair_wise.trace}")
      # for testing algorithms
      CSV.open("/tmp/D-matrix-#{@assignment.id.to_s}.csv","w") do |writer|
        pair_wise.size1.times do |i|
          writer << [ submissions[i].user.id ] + pair_wise.row(i).to_a
        end
      end
      pair_wise = (pair_wise + pair_wise.transpose) / 2
      eigenval,eigenvec = pair_wise.eigen_symmv
      GSL::Eigen::symmv_sort(eigenval,eigenvec, GSL::Eigen::SORT_VAL_DESC)
      trust_vector = eigenvec.column(0)
      trust_vector = trust_vector * -1 unless trust_vector.isnonneg?
      Rails.logger.info("Eigenvalues: #{eigenval}")
      Rails.logger.info("Eigenvector: #{trust_vector}")
      max_trust = trust_vector.max
      min_trust = trust_vector.min
      if min_trust < -1.0e-10
        Rails.logger.info("---------\n\n      Uh oh!  min trust is less than zero: #{min_trust}\n\n---------------\n")
      end
      trust_vector.scale!(1.0/max_trust) if max_trust != 0.0
      num_students.times do |i|
        if trust_vector[i] < 1.0e-10
          submissions[i].update_attribute( :trust, 0 )
        else
          submissions[i].update_attribute( :trust, trust_vector[i] )
        end
      end
  end


  #
  # Calculates the similarity in two scores on a scale of 0.0 to 1.0,
  # inclusive.  Input scores are assumed to be between 0.0 and 100.0,
  # inclusive.
  #
  def calculate_similarity(a,b)
    return 0 if a.nil? || b.nil?
    1.0 - (a-b)*(a-b)/10000.0
  end

  def calculate_final_score_fn
    '(0.15*peer_edit_participant + 0.10*peer_edit_author + 0.25 * eval_author + 0.5 * eval_participant)'
  end
        
  def calculate_final_score(data)
    fvars = data.keys.map{ |t| %{#{t} = (data.#{t} or 100)} }.join("\n")
    self.lua_call('calculate_final_score', "#{fvars}\nresult = #{self.calculate_final_score_fn}\nreturn result", 'data', data)
  end

protected
        
 def lua_call(fname, fbody, data_name, data)
    lua = self.lua_context
          
    lua.eval("temp159 = type(#{fname})")
    if lua.get("temp159") != 'function'
              
      lua.eval("function #{fname}(#{data_name})\n#{fbody}\nend")
      lua.eval("temp159 = type(#{fname})")
      if lua.get("temp159") != 'function'
        raise "Unable to define the function '#{fname}' in Lua"
      end
    end

    lua.call(fname, data)
  end

  def lua_debug(x)
    Rails.logger.info(">>>>>>>>>>>>>>> From LUA: \n" + YAML::dump(x) + "\n^^^^^^^^^^^^^^")
  end

  def lua_context
    if !defined? @lua_context
      @lua_context = Lua.new('baselib', 'mathlib', 'stringlib')
      @lua_context.setFunc('debug', self, 'lua_debug')
    end

    @lua_context
  end
end

class AssignmentDrop < Liquid::Drop
  attr_accessor :assignment

  def course
    d.course.to_liquid
  end

  def assignment_modules
    d.assignment_modules.map { |am| am.to_liquid }
  end
end
