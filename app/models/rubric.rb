class Rubric < ActiveRecord::Base
  belongs_to :course
  has_many   :prompts, :dependent => :destroy

  def user
    self.course.user
  end

  def assignments
    # collect all of the assignments we're part of (includes assignments
    # and assignment modules)
    []
  end

  #
  # Calculates the grade for the particular rubric given the data from
  # the student and the Lua function defined for this rubric.  Provides
  # prompt tags as convenience variables for the prompt responses.
  #
  # For example, if a rubric has two prompts, one tagged 'content' and
  # the other tagged 'style', then the variables 'content' and 'style'
  # will have the response scores for the respective prompts.  The
  # formula could then be something like `60 + 5*(content + style)`.
  #
  # If the calculated score is below the minimum, then the floor is
  # returned.  If the calculated score is above the maximum, then the
  # ceiling is returned.
  #
  def calculate_score(data)
#    Rails.logger.info(">>>>>>> calculate_fn: #{self.calculate_fn}")
#    Rails.logger.info(">>>>>>> data: #{YAML::dump(data)}")
    return 0 if self.calculate_fn.blank?
    return 0 if data.nil? || data.empty?
    tags = self.prompts.collect{|p| p.tag }

    ## at least until we convert stuff
    md = { }
    self.prompts.each do |p|
      md[p.tag] = (data[p.tag] || data[(p.position-1).to_s] || data[p.position-1] || 0).to_i
    end

    parser = Fabulator::Expr::Parser.new
    context = Fabulator::Expr::Context.new
    context.merge_data(md)
    parsed = parser.parse(self.calculate_score_fn, context)
    raw = parsed.run(context).first.to([Fabulator::FAB_NS, 'numeric']).to_f 

#    Rails.logger.info(">>> score >>> #{raw}")
    if !self.minimum.nil?
      if self.inclusive_minimum?
        return self.floor if raw <= self.minimum
      else
        return self.floor if raw < self.minimum
      end
    end
    if !self.maximum.nil?
      if self.inclusive_maximum?
        return self.ceiling if raw >= self.maximum
      else
        return self.ceiling if raw > self.maximum
      end
    end
    return raw
  end

  #
  # Returns a Hash representing the rubric.  The `:instructions` key
  # associates with Rubric#instructions.  The `:prompts` key associates
  # with an Array of Hashes representing the Rubric#prompts.
  #
  def to_h
    { :instructions => self.instructions,
      :prompts => self.prompts.sort_by(&:position).map { |p| p.to_h }
    }
  end

end
