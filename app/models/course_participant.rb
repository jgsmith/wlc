class CourseParticipant < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  def is_student?
    level == 0
  end

  def is_assistant?
    level > 0
  end

  def is_designer?
    level > 1
  end
end
