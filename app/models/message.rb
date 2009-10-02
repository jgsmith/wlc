class Message < ActiveRecord::Base
  belongs_to :assignment_participation
  belongs_to :user
  has_many :uploads, :as => :holder

  def can_user_view_upload?(u)
    self.user == u ||
    self.assignment_participation.user == u ||
    self.assignment_participation.assignment_submission.user == u ||
    self.assignment_participation.assignment_submission.assignment.course.is_assistant?(u)
  end

  def can_user_view_message?(u)
    self.can_user_view_upload?(u)
  end

  def download_filename_prefix
    return assignment_participation.download_filename_prefix
  end
end
