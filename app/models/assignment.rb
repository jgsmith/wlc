class Assignment < ActiveRecord::Base
  belongs_to :course
  belongs_to :assignment_template

  has_many :assignment_modules
  has_many :assignment_submissions

  acts_as_list :scope => :course_id

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
      end

      @configured_modules = m_list
    end

    return @configured_modules
  end

  def current_module(user)
    if !defined? @current_module
      n = Time.now
      @current_module = configured_modules(user).select{|c| c.starts_at <= n}.sort_by(&:starts_at).last
    end

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
