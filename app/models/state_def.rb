class StateDef < ActiveRecord::Base
  belongs_to :module_def
  has_many   :transition_defs, :foreign_key => :from_state_id

  serialize  :view_form

  def pre(participation)
    if !pre_fn.blank?
      participation.lua_call("pre_#{self.id}", pre_fn)
    end
  end

  def post(participation)
    if !post_fn.blank?
      participation.lua_call("post_#{self.id}", post_fn)
    end
  end
end
