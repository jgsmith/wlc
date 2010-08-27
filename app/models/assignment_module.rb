class AssignmentModule < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :module_def

  belongs_to :author_rubric, :class_name => 'Rubric'
  belongs_to :participant_rubric, :class_name => 'Rubric'
  acts_as_list :scope => :assignment_id

  has_many :scores

  validates_numericality_of :number_participants, :only_integer => true, :greater_than_or_equal_to => 1, :allow_nil => true, :allow_blank => true
  validates_format_of :tag, :with => /^[a-z][a-z0-9_]+$/, :allow_nil => true, :allow_blank => true
  validates_presence_of :tag, :if => Proc.new { |m| m.is_evaluative? }
  validates_uniqueness_of :tag, :scope => :assignment_id, :allow_nil => true, :allow_blank => true
  validates_presence_of   :assignment_id

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


  def module_type
    if self.has_messaging?
      return -1
    elsif self.module_def.nil?
      return 0
    else
      return self.module_def.id
    end
  end

  def module_type=(m)
    if m.to_i == -1
      self.has_messaging = true
      self.module_def = nil
    elsif m.to_i == 0
      self.has_messaging = false
      self.module_def = nil
    else
      self.module_def = ModuleDef.find(m.to_i)
    end
  end

  def params_context
    ctx = Fabulator::Expr::Context.new
    if self.params.nil?
      ctx.root = ctx.root.anon_node(nil)
      ctx.root.axis = 'sys'
      ctx.root.roots['sys'] = ctx.root
    else
      ctx.root = self.params
      ctx.root.roots['sys'] = ctx.root
    end
    ctx
  end

  def params_form
    return '' if module_def.nil?
    parser = Fabulator::Template::Parser.new
    ctx = self.params_context
    doc = parser.parse(ctx, "<view><form id='params'>" + module_def.params + "<submit><caption>Update Parameters</caption></submit></form></view>")
    doc.add_default_values(ctx)
    doc.to_html(:form => false)
  end

  def is_evaluative?
    return false if self.has_messaging
    return false if self.module_def.nil?
    return self.module_def.is_evaluative?
  end

  def ends_at
    cms = self.assignment.configured_modules(nil)
    cms[self.position - 1].ends_at
  end

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
