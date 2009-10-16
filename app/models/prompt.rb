class Prompt < ActiveRecord::Base
  belongs_to :rubric
  has_many   :responses

  #acts_as_list :scope => 'rubric_id'

  def to_h
    { :tag => self.tag,  
      :prompt => self.prompt,
      :position => self.position, 
      :responses => self.responses.map { |rr| rr.to_h }
    }   
  end

end
