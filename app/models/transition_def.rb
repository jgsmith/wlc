class TransitionDef < ActiveRecord::Base
  belongs_to :from_state, :class_name => 'StateDef'
  belongs_to :to_state, :class_name => 'StateDef'

  def process_params(participation)
    if process_fn.blank?
      from_state.post(participation)
      to_state.pre(participation)
    else
      participation.lua_call("process_#{self.id}", process_fn)
    end
  end

  def validate_params(participation)
    if !validate_fn.blank?
      return participation.lua_call("validate_#{self.id}", validate_fn)
    end
    return {
      :score => 0,
      :valid => { }
    }
  end
end
