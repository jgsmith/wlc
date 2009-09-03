class Assignment < ActiveRecord::Base
  belongs_to :course
  belongs_to :assignment_template

  has_many :assignment_modules
  has_many :assignment_submissions

  acts_as_list :scope => :course_id

  serialize :participant_eval
  serialize :author_eval

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

      cur_time = self.starts_at
      m_list.each do |m|
        m.starts_at = cur_time
        cur_time += m.duration.to_i
        m.assignment = self
        m.is_evaluation = false
      end

      @configured_modules = m_list

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
        m.starts_at = @configured_modules.last.ends_at
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
      n = Time.now
      @current_module = configured_modules(user).select{|c| c.starts_at <= n}.sort_by(&:starts_at).last
    end

    return nil if @current_module.ends_at < Time.now()

    return @current_module
  end

  def ends_at
    @ends_at ||= self.configured_modules(nil).last.ends_at
    @ends_at
  end

  def to_liquid
    d = AssignmentDrop.new
    d.assignment = self
    d
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
