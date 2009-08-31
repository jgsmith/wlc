class Message < ActiveRecord::Base
  belongs_to :assignment_participation
  belongs_to :user
end
