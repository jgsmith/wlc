class Course < ActiveRecord::Base
  belongs_to :user
  belongs_to :semester

  has_many :course_participants
  has_many :assignments, :order => 'starts_at'

  def is_student?(u)
    CourseParticipant.count(:conditions => [ 'course_id = ? AND user_id = ? AND level = 0',
      self.id, u.id ]) > 0
  end
end
