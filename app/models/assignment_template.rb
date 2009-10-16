class AssignmentTemplate < ActiveRecord::Base
  belongs_to :user

  belongs_to :author_rubric, :class_name => 'Rubric'
  belongs_to :participant_rubric, :class_name => 'Rubric'

  has_many :assignment_template_modules

  serialize :old_participant_eval
  serialize :old_author_eval

  def author_eval
    if author_rubric
      author_rubric.to_h
    else
      old_author_eval
    end
  end

  def participant_eval
    if participant_rubric
      participant_rubric.to_h
    else
      old_participant_eval
    end
  end

  def configured_modules(user)
    self.assignment_template_modules.map { |atm|
      atm.configured_module(user)
    }
  end
end
