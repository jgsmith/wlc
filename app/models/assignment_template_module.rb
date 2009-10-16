class AssignmentTemplateModule < ActiveRecord::Base
  belongs_to :assignment_template
  belongs_to :module_def

  belongs_to :author_rubric, :class_name => 'Rubric'
  belongs_to :participant_rubric, :class_name => 'Rubric'

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

  acts_as_list :scope => 'assignment_template_id'

  def configured_module(user)
    if self.module_def.nil?
      cm = ConfiguredModule.new
      cm.user = user
    else
      cm = self.module_def.configured_module(user)
    end
    cm.apply_module(self)
    cm
  end  
end
