class StateDef < ActiveRecord::Base
  belongs_to :module_def
  #has_many   :transition_defs, :foreign_key => :from_state_id

  #serialize  :view_form
end
