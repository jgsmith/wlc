class AssignmentModule < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :module_def

  serialize :author_eval
  serialize :participant_eval

  def configured_module(user)
    cm = module_def.configured_module(user)
    cm.apply_module(self)
  end
end
