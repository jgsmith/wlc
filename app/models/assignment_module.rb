class AssignmentModule < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :module_def

  belongs_to :author_rubric, :class_name => 'Rubric'
  belongs_to :participant_rubric, :class_name => 'Rubric'

  has_many :scores

  serialize :old_author_eval
  serialize :old_participant_eval
  serialize :params

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
