require 'tzinfo'

class Course < ActiveRecord::Base
  belongs_to :user
  belongs_to :semester

  has_many :course_participants
  has_many :assignments, :order => 'position'

  def tz
    @tz ||= TZInfo::Timezone.get(self.timezone)
    @tz
  end

  # the .utc makes sure we convert to utc first regardless of the tz of
  # the server we're running on
  def now
    @now ||= tz.utc_to_local(Time.now.utc)
    @now
  end

  def is_student?(u)
    cp = CourseParticipant.first(
      :conditions => [ 
        'course_id = ? AND user_id = ?',
        self.id, u.id 
      ]
    ) rescue nil

    cp && cp.is_student?
  end

  def is_instructor?(u)
    self.user == u
  end

  def is_designer?(u)
    return true if is_instructor?(u)

    cp = CourseParticipant.first(
      :conditions => [ 
        'course_id = ? AND user_id = ?',
        self.id, u.id 
      ]
    ) rescue nil

    cp && cp.is_designer?
  end

  def is_assistant?(u)
    return true if is_instructor?(u)

    cp = CourseParticipant.first(
      :conditions => [ 
        'course_id = ? AND user_id = ?',
        self.id, u.id 
      ]
    ) rescue nil

    cp && cp.is_assistant?
  end

  def current_assignments
    self.assignments.select{|a| 
      a.utc_starts_at < self.now && a.utc_ends_at > self.now }
  end

  def has_current_assignment?
    self.assignments.each do |a|
      return true if a.utc_starts_at <= self.now && a.utc_ends_at >= self.now
    end
    return false
  end
end
