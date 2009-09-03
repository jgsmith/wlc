class AssignmentParticipation < ActiveRecord::Base
  belongs_to :assignment_submission
  belongs_to :user
  belongs_to :state_def

  has_many :uploads, :as => :holder

  serialize :context
  serialize :author_eval
  serialize :participant_eval

  attr_accessor :data
  attr_accessor :params

  # you have to be a participant in this submission's thread and not be
  # earlier than the module during which this upload was done
  # OR you can be the course instructor
  def can_user_view_upload?(u)
    self.assignment_submission.assignment.course.user == u ||
    self.assignment_submission.assignment_participations.select{|p|
      p.position >= self.position &&
      p.user == u
    }.size > 0
  end

  def assignment
    if !self.assignment_submission.nil?
      self.assignment_submission.assignment
    else
      @assignment
    end
  end

  def assignment=(a)
    @assignment = a
  end

  def configured_module=(c)
    @configured_module = c
    self.assignment = c.assignment
    self.user = c.user
  end

  def configured_module
    @configured_module ||= self.assignment.configured_modules(self.user)[self.position-1]
    @configured_module
  end

  def download_filename_prefix
    if configured_module
      return configured_module.download_filename_prefix
    else
      return 'download'
    end
  end

  def view_text
    if defined? self.state_def
      self.render self.state_def.view_text
    else
      ''
    end
  end

  def view_form
    if !self.state_def.nil? && !self.state_def.view_form.nil?
      self.state_def.view_form.dup 
    else
      { }
    end
  end

  def show_info
    if configured_module.nil? || configured_module.module_def.nil?
      ''
    else
      self.render self.configured_module.module_def.show_info
    end
  end

  def initialize_participation
    return if self.configured_module.module_def.nil?
    self.configured_module.module_def.initialize_participation(self)
  end

  def process_params(params)
    return if self.configured_module.module_def.nil?
    self.params = params

    @data = { }

    params.each_pair do |k,v|
      @data[k] = v unless v.kind_of?(ActionController::UploadedFile)
    end

    best_score = 0
    best_errors = nil
    best_valid = { }
    best_transition = nil
    self.state_def.transition_defs.each do |transition|
      r = transition.validate_params(self)
      if r['score'] > best_score
        best_score = r['score']
        best_errors = r['errors']
        best_valid = r['valid']
        best_transition = transition
      end
    end

    if !best_transition.nil? && best_errors.nil? || best_errors.empty?
      # take this transition
      self.data = best_valid
      begin
        best_transition.process_params(self)
      rescue Exception => e
        if e.message =~ /^goto (.+)$/
          new_state = state_def.module_def.state_defs.select { |s| s.name == $1 }.first
          self.state_def = new_state
        else
          raise
        end
      else
        self.state_def = best_transition.to_state
      end
      self.save
      return true
    else
      return false
    end
  end

  def render(template)
    Liquid::Template.parse(template).render({
      'data' => self.data,
      'participation' => self.to_liquid,
      'dates' => {
        'assignment' => {
        },
        'module' => {
        }
      }
    })
  end

  def to_liquid
    d = AssignmentParticipationDrop.new
    d.assignment_participation = self
    d
  end

  def lua_goto(sname)
    raise "goto #{sname}"
  end

  def lua_pre(sname)
    s = self.state_def.module_def.state_defs.select { |s| s.name == sname }
    if defined? s
      s.pre(self)
    end
  end

  def lua_post(sname)
    s = self.state_def.module_def.state_defs.select { |s| s.name == sname }
    if defined? s
      s.post(self)
    end
  end

  def lua_has_upload(pname)
    @params[pname].kind_of?(ActionController::UploadedFile)
  end

  def lua_has_attached_upload(pname)
    return !self.new_record? && self.uploads.select{ |u| u.tag == pname }.size > 0
  end

  def lua_attach_upload(pname)
    if lua_has_upload(pname)

      ensure_submission

      u = Upload.first(:conditions => [
        "holder_type = 'AssignmentParticipation' AND holder_id = ? AND tag = ?",
        self.id, pname
      ])

      if u.nil?
        u = Upload.new
        u.user = self.user
        u.holder = self
        u.tag = pname
      end

      u.upload = @params[pname]
      u.save
    end
  end

  def lua_call(fname, fbody)
    lua = self.lua_context

    lua.eval("temp159 = type(#{fname})")
    if lua.get("temp159") != 'function'
      
      lua.eval("function #{fname}(data)\n#{fbody}\nend")
      lua.eval("temp159 = type(#{fname})")
      if lua.get("temp159") != 'function'
        raise "Unable to define the function '#{fname}' in Lua"
      end
    end

    lua.call(fname, self.data || {})
  end

protected

  def ensure_submission
    return unless self.position == 1

    if self.assignment_submission.nil?
      as = AssignmentSubmission.create(
        :user => user,
        :assignment => assignment
      )
      as.save

      self.assignment_submission = as
      self.save
    end

    if self.new_record?
      self.save
    end
  end

  def lua_context
    if !defined? @lua_context
      @lua_context = Lua.new('baselib', 'mathlib', 'stringlib')

      @lua_context.setFunc('goto', self, 'lua_goto')
      @lua_context.setFunc('pre', self, 'lua_pre')
      @lua_context.setFunc('post', self, 'lua_post')

      @lua_context.setFunc('has_upload', self, 'lua_has_upload')
      @lua_context.setFunc('attach_upload', self, 'lua_attach_upload')
      @lua_context.setFunc('has_attached_upload', self, 'lua_has_attached_upload')
    end

    @lua_context
  end
end

class AssignmentParticipationDrop < Liquid::Drop
  attr_accessor :assignment_participation

  def user
    assignment_participation.user.to_liquid
  end

  def uploads
    assignment_participation.uploads.map { |u| u.to_liquid }
  end
end
