class AssignmentSubmission < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user

  serialize :author_eval
  serialize :scores

  has_many :assignment_participations

  def show_info(position, u = nil)
    # we want to show all of the information up to the specified position

    assignment_participations.select{ |ap| ap.position < position && ap.user == self.user }.map { |ap| ap.show_info(u) }.join("")
  end

  def view_scores
    return ''
    self.calculate_scores if self.scores.nil? || self.scores.empty?
    Liquid::Template.parse(self.assignment.score_view).render({
      'scores' => self.scores,
    })
  end

  def calculate_score(use_trust)
    raw_data = { }
    self.assignment.scores.find(:all, :conditions => [ 'user_id = ?', self.user.id ]).each do |score|
      raw_data[score.tag + '_author'] = score.author_score
      raw_data[score.tag + '_participant'] = score.participant_score
    end
    self.update_attribute(
      :score,
      self.assignment.calculate_final_score(raw_data)
    )
  end

protected

  def tag_responses(rubric,responses)
    tagged = { }

    return tagged if responses.nil? || responses.size == 0

    responses.size.times do |i|
      if !rubric[:prompts][i].nil?
        tagged[rubric[:prompts][i][:tag]] = responses[i]
      end
    end

    return tagged
  end
end
