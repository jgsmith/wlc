class AssignmentTemplate < ActiveRecord::Base
  belongs_to :user

  has_many :assignment_template_modules

  serialize :participant_eval
  serialize :author_eval

  def configured_modules(user)
    self.assignment_template_modules.map { |atm|
      atm.configured_module(user)
    }
  end
end
