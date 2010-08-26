require 'tzinfo'

class Course < ActiveRecord::Base
  belongs_to :user
  belongs_to :semester

  has_many :course_participants
  has_many :assignments, :order => 'position'
  has_many :rubrics

  def tz
    @tz ||= (TZInfo::Timezone.get(self.timezone) rescue TZInfo::Timezone.get('America/Chicago'))
    @tz
  end

  def user_uin
    @user.nil? ? nil : @user.uin
  end

  def user_uin=(uin)
    u = User.find_by_uin(uin)
    if u.nil?
    end
    if !u.nil?
      self.user = u
    end
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
    return false if u.nil?

    return true if is_instructor?(u)

    cp = CourseParticipant.first(
      :conditions => [ 
        'course_id = ? AND user_id = ?',
        self.id, u.id 
      ]
    ) rescue nil

    cp && cp.is_assistant?
  end

  def assistants
    User.find(:all,
      :joins => [ :course_participants ],
      :select => 'DISTINCT users.*',
      :conditions => [ %{
        course_participants.course_id = ?
        AND course_participants.level > 1
      }, self.id],
      :order => 'name'
    )
  end

  def designers
    User.find(:all,
      :joins => [ :course_participants ],
      :select => 'DISTINCT users.*',
      :conditions => [ %{
        course_participants.course_id = ?
        AND course_participants.level > 0
      }, self.id],
      :order => 'name'
    )
  end

  def students
    User.find(:all,
      :join => [ :course_participants ],
      :select => 'DISTINCT users.*',
      :conditions => [ %{
        course_participants.course_id = ?
        AND course_participants.level = 0
      }, self.id],
      :order => 'name'
    )
  end

  def student_count
    self.course_participants.count(:conditions => ['level = 0'])
  end

  def current_assignments
    self.assignments.select{|a| 
      a.utc_starts_at < self.now && a.utc_ends_at > self.now }
  end

  def has_current_assignment?
    self.assignments.each do |a|
      next if a.utc_starts_at.nil?
      return true if a.utc_starts_at <= self.now && a.utc_ends_at >= self.now
    end
    return false
  end
end
