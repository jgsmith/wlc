class Response < ActiveRecord::Base
  belongs_to :prompt

  #acts_as_list :scope => 'prompt_id'

  def to_h
    { :score => self.score,
      :response => self.response,
      :position => self.position
    }
  end
end
