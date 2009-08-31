class ModuleDef < ActiveRecord::Base
  has_many :state_defs

  def initialize_participation(participation)
    participation.state_def = state_defs.select{ |s| s.name == 'start' }.first
    if !self.init_fn.blank?
      begin
        participation.lua_call('initialize', self.init_fn)
      rescue Exception => e
        if e.message =~ /^goto (.+)$/
          new_state = $1
          participation.state_def = state_defs.select{ |s| s.name == new_state }.first
        else
          raise
        end
      end
    end
  end

  def configured_module(user)
    cm = ConfiguredModule.new
    cm.module_def = self
    cm.user = user
    cm.download_filename_prefix = self.download_filename_prefix
    cm
  end
end
