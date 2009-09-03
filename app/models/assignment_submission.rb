class AssignmentSubmission < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user

  serialize :author_eval

  has_many :assignment_participations

  def show_info(position)
    # we want to show all of the information up to the specified position

    assignment_participations.select{ |ap| ap.position < position && ap.user == self.user }.map { |ap| ap.show_info }.join("")
  end
end
