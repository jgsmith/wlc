class Course < ActiveRecord::Base
  belongs_to :user
  belongs_to :semester

  has_many :course_participants
  has_many :assignments, :order => 'starts_at'
end
