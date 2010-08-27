class AssignmentParticipation < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  include ActionController::UrlWriter

  belongs_to :assignment_submission
  belongs_to :user
#  belongs_to :state_def
  has_many :uploads, :as => :holder

  serialize :context
  serialize :author_eval
  serialize :participant_eval

  attr_accessor :data
  attr_accessor :params
  attr_accessor :viewing_user

  def initialize
    super
  end

  def roots
    if self.context.nil?
      self.initialize_participation
    end
    if self.context.nil?
      { }
    else
      self.context[:roots]
    end
  end

  def expr_context
    assignment_module.configured_module(user).context.with_root(
      self.context[:data]
    )
  end

  def state
    self.context[:state]
  end

  def assignment_module
    AssignmentModule.first :conditions => [
      'assignment_id = ? AND tag = ?',
      self.assignment.id,
      self.tag
    ]
  end

  def position
    if self.assignment_module.nil?
      self.assignment.assignment_modules.last.position + 1
    else
      self.assignment_module.position
    end
  end

  # you have to be a participant in this submission's thread and not be
  # earlier than the module during which this upload was done
  # OR you can be the course instructor
  def can_user_view_upload?(u)
    self.assignment_submission.assignment.course.is_assistant?(u) ||
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
    @configured_module ||= self.assignment.configured_modules(self.user)[self.position - 1]
    @configured_module
  end

  def download_filename_prefix
    if !self.configured_module.nil?
      return self.configured_module.download_filename_prefix
    else
      return 'download'
    end
  end

  def state_def
    if self.configured_module.nil?
      return nil
    end

    if self.state.nil?
      return nil
    end

    candidates = self.configured_module.module_def.state_defs.select{ |s|
      s.name == self.state
    }
    return candidates.first
  end

  def view_text
    if !self.state_def.nil?
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

  def show_info(u = nil)
    if configured_module.nil? || configured_module.module_def.nil?
      ''
    else
      self.viewing_user = u
      self.render self.configured_module.module_def.show_info
    end
  end

  def initialize_participation
    return if self.configured_module.module_def.nil?

    ctx = {
      :state => 'start',
      :roots => {
      }
    }

    ctx[:roots]['data'] = Fabulator::Expr::Node.new('data', ctx[:roots], nil, [])

    self.context = ctx
    self.configured_module.module_def.initialize_participation(self)
  end

  def process_params(params)
    return if self.configured_module.module_def.nil?

    sm = self.configured_module.module_def.state_machine
    sm.context = self.context

    params.delete("format")
    params.delete("assignment_id")
    params.delete("action")
    params.delete("authenticity_token")
    params.delete("_method")
    params.delete("controller")
    params.keys.each do |k|
      next if params[k].is_a?(String)
      if params[k].is_a?(Tempfile)
        file = TempFile.new
        file.holder = self
        file.upload = params[k] 
        file.save
        params[k] = sm.context[:data].root.anon_node("#{file.class.name} #{file.id}", [ Fabulator::ASSETS_NS, 'asset' ])
        params[k].set_attribute('size', file.size)
        params[k].set_attribute('content_type', file.content_type)
        params[k].set_attribute('original-filename', file.filename)
        params[k].set_attribute('user', self.user.id)
      end
    end

    self.ensure_submission
    sm.run(params)
    @sm_missing_args = sm.missing_params
    @sm_errors       = sm.errors

    ctx = sm.context
    ctx[:data].root.roots.keys.each do |k|
      next if k == 'data'
      ctx[:data].root.roots.delete(k)
    end
    self.context = ctx
    self.save
    return true
  end

  def render(template)
    parser = Fabulator::Template::Parser.new
    c = self.expr_context

    c.root.roots['data'] = self.data
    c.root.roots['sys'] = self.assignment_module.params
    if c.root.roots['sys'].nil?
      c.root.roots['sys'] = c.root.anon_node(nil)
    end
    c.root.roots['sys'].axis = 'sys'
    c.with_root(c.root.roots['sys']).merge_data({
      'user' => self.viewing_user.nil? ? 0 : self.viewing_user.id,
      'dates' => {
        'assignment' => {
          'starts-at' => distance_of_time_in_words(self.assignment.starts_at, self.assignment.course.now),
          'ends-at' => distance_of_time_in_words(self.assignment.ends_at, self.assignment.course.now)
        },
        'module' => {
          'starts-at' => distance_of_time_in_words(self.configured_module.starts_at, self.assignment.course.now),
          'ends-at' => distance_of_time_in_words(self.configured_module.ends_at, self.assignment.course.now),
        },
        'participation' => {
          'participant-name' => (self.assignment.course.is_assistant?(self.viewing_user) ? self.user.name : '')
        },
      }
    })
    parser.parse(c, template).to_s
  end

  def get_form_info(opts)
    ctrl = opts[:controller]
    form = {
      :content => self.view_form
    } 
    # XML - need to add values, captions, etc.
        
    args = { }
    if opts[:user] != opts[:real_user]
      args[:user_id] = opts[:user]
      if !params[:module].blank?
        args[:module] = params[:module]
      end
    end
    if !form[:content].blank?

      xml = %{<view><form>} + form[:content] + %{</form></view>}

      mod_ctx = self.assignment_module.params_context

      tmpl_parser = Fabulator::Template::Parser.new
      parsed = tmpl_parser.parse(self.expr_context, xml)
      if !parsed.is_a?(String)
        parsed.add_captions(mod_ctx.with_root(mod_ctx.eval_expression("sys::/params/field-labels").first))
      end
      form[:content] = parsed.is_a?(String) ? parsed : parsed.to_html(:form => false)

      if self.position == 1
        form[:id] = "participation-s-#{opts[:user].id}"
      else
        form[:id] = "participation-#{self.id}"
      end

      # now we want to convert the form info to something we can use in ExtJS
      # this is temporary

      # should check for an <asset/> element
      form[:fileUpload] = true
    
      if self.new_record?
        args[:assignment_id] = self.assignment
        form[:show_url] = assignment_assignment_participations_path(args)
        args[:format] = 'ext_json' + (form[:fileUpload] ? '_html' : '')
        form[:url] = assignment_assignment_participations_path(args)
        form[:method] = 'POST'
      else
        args[:action] = 'show'
        args[:controller] = 'assignment_participations'
        args[:id] = self
        form[:show_url] = url_for(args) # assignment_participation_path(args)
        args[:format] = 'ext_json' + (form[:fileUpload] ? '_html' : '')
        form[:url] = url_for(args)
        form[:method] = 'PUT'
      end
      form[:content] += "<input type='hidden' name='authenticity_token' value='#{ctrl.form_authenticity_token}'/>"
      form[:content] += "<input type='hidden' name='_method' value='#{form[:method]}' />"

      cstate = self.state_def.nil? ?  'start' : self.state_def.name.to_s

      submit_label = mod_ctx.eval_expression("sys::/params/submit-labels/#{cstate}").first
      if !submit_label.nil? && !submit_label.to_s.blank?
        form[:submit] = submit_label.to_s
      end
    end
    form
  end


protected

  def ensure_submission
    return unless self.assignment_module && self.assignment_module.position == 1

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

end
