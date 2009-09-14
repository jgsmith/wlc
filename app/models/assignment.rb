class Assignment < ActiveRecord::Base
  belongs_to :course
  belongs_to :assignment_template

  has_many :assignment_modules
  has_many :assignment_submissions

  acts_as_list :scope => :course_id

  serialize :participant_eval
  serialize :author_eval

  def starts_at
    self.course.tz.utc_to_local(self.utc_starts_at)
  end

  def starts_at=(t)
    self.utc_starts_at = self.course.tz.local_to_utc(t)
  end

  def ends_at
    self.course.tz.utc_to_local(self.utc_ends_at)
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
      if !self.assignment_template.nil?
        m_list = self.assignment_template.configured_modules(user)
        self.assignment_modules.each do |am|
          m_list[am.position].apply_module(am)
        end
      else
        self.assignment_modules.each do |am|
          m_list[am.position] = am.configured_module(user)
        end
      end

      cur_time = self.utc_starts_at
      m_list.each do |m|
        next if m.nil?
        m.utc_starts_at = cur_time
        cur_time += m.duration.to_i
        m.assignment = self
        m.is_evaluation = false
      end

      @configured_modules = m_list.select{ |m| !m.nil? }

      if @configured_modules.select{ |cm| cm.has_evaluation? }.size > 0 ||
         !self.participant_eval.nil? && !self.participant_eval.empty?   ||
         !self.author_eval.nil? && !self.author_eval.empty? ||
         !self.assignment_template.nil? && (
           !self.assignment_template.participant_eval.nil? &&
           !self.assignment_template.participant_eval.empty? ||
           !self.assignment_template.author_eval.nil? &&
           !self.assignment_template.author_eval.empty? 
         )
        m = ConfiguredModule.new
        m.utc_starts_at = @configured_modules.last.utc_ends_at
        m.tag = self.eval_tag
        m.position = @configured_modules.last.position + 1
        m.is_evaluation = true
        m.user = user
        m.assignment = self
        m.instructions = ''
        if !self.assignment_template.nil?
          m.name = self.assignment_template.eval_name
          m.duration = self.assignment_template.eval_duration
          m.author_name = self.assignment_template.author_name
          m.participant_eval = self.assignment_template.participant_eval
          m.author_eval = self.assignment_template.author_eval
          m.number_participants = self.assignment_template.number_evaluations
        end
        m.name = self.eval_name unless self.eval_name.blank?
        m.duration = self.eval_duration unless self.eval_duration < 1
        m.author_name = self.author_name unless self.author_name.blank?
        m.participant_eval = self.participant_eval unless self.participant_eval.nil?
        m.author_eval = self.author_eval unless self.author_eval.nil?
        m.number_participants = self.number_evaluations unless self.number_evaluations < 1
        if m.participant_eval.nil? || m.participant_eval.empty?
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

  def calculate_scores(raw_data)
    return { } if self.calculate_score_fn.blank?
    self.lua_call('calculate_score', self.calculate_score_fn, 'scores', raw_data)
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

  def assignment_template
    d.assignment_template.to_liquid
  end

  def assignment_modules
    d.assignment_modules.map { |am| am.to_liquid }
  end
end
