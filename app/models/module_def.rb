require 'xml/libxml'

class ModuleDef < ActiveRecord::Base
  has_many :state_defs

  serialize :params

  def state_machine
    @state_machine ||= Fabulator::Core::StateMachine.new.compile_xml(LibXML::XML::Document.string self.xml_definition)
    @state_machine
  end

  def states
    self.state_machine.state_names
  end

  def references_state?(s)
    self.states.include?(s)
  end

  def context
    state_machine.fabulator_context
  end

  def initialize_participation(participation)
    context = Fabulator::Expr::Context.new
    context.root = participation.roots['data']
    self.state_machine.init_context(context)
  end

  def configured_module(user)
    cm = ConfiguredModule.new
    cm.module_def = self
    cm.user = user
    cm.download_filename_prefix = self.download_filename_prefix
    cm
  end
end
