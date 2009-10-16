class Rubric < ActiveRecord::Base
  belongs_to :user
  has_many   :prompts

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
#    Rails.logger.info(">>>>>>> data keys: #{data.keys.join(', ')}")
    tags = self.prompts.collect{|p| p.tag }

    ## at least until we convert stuff
    md = { }
    self.prompts.each do |p|
#      Rails.logger.info(">>>> #{p.tag} == #{p.position-1}")
      md[p.tag] = (data[p.tag] || data[(p.position-1).to_s] || data[p.position-1] || 0).to_i
    end
#    Rails.logger.info(YAML::dump(md))
    raw = self.lua_call('calculate', self.calculate_fn,tags,md)
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
      :prompts => self.prompts.map { |p| p.to_h }
    }
  end

protected

  # Returns a Lua interpreter object
  def lua_context
    if !defined? @lua_context 
      @lua_context = Lua.new('baselib', 'mathlib', 'stringlib')
    end
    return @lua_context
  end

  # Runs the given function with the given data.  Compiles the function if
  # it has not been compiled yet for the Lua context associated with the
  # Rubric.
  def lua_call(fname, fbody, tags, data)
    return 0 if tags.nil? || tags.empty?

#    Rails.logger.info(YAML::dump(data))
    lua = self.lua_context
    lua.eval("temp159 = type(#{fname})")
    if lua.get("temp159") != 'function'
      fvars = tags.map{ |t| %{#{t} = (data.#{t} or 0)} }.join("\n") 
#      Rails.logger.info("function #{fname}(data)\n#{fvars}\nresult = #{fbody}\nreturn result\nend")
      lua.eval("function #{fname}(data)\n#{fvars}\nresult = #{fbody}\nreturn result\nend")
      lua.eval("temp159 = type(#{fname})")
      if lua.get("temp159") != 'function'
        raise "Unable to define the function '#{fname}' in Lua"
      end
    end

#    Rails.logger.info("Calling into Lua with data=:#{YAML::dump(data)}")
    lua.call(fname, data)
  end
end
