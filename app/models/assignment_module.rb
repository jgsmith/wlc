class AssignmentModule < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :module_def

  serialize :author_eval
  serialize :participant_eval
  serialize :params

  validates_uniqueness_of :tag, :scope => :assignment_id
  validates_presence_of   :tag
  validates_presence_of   :assignment_id

  def configured_module(user)
    if self.module_def.nil?
      cm = ConfiguredModule.new
      cm.user = user
    else
      cm = module_def.configured_module(user)
    end
    cm.apply_module(self)
    cm
  end
end
