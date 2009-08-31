class AssignmentTemplateModule < ActiveRecord::Base
  belongs_to :assignment_template
  belongs_to :module_def

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
