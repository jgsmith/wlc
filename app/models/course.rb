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
    CourseParticipant.count(:conditions => [ 'course_id = ? AND user_id = ? AND level = 0',
      self.id, u.id ]) > 0
  end
end
