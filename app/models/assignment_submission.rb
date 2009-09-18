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
    self.calculate_scores if self.scores.nil? || self.scores.empty?
    Liquid::Template.parse(self.assignment.score_view).render({
      'scores' => self.scores,
    })
  end

  def calculate_scores
    return { } if self.assignment.calculate_score_fn.blank?

    raw_data = { }
    self.assignment.configured_modules(self.user).each do |m|
      if m.has_evaluation?
        raw_data[m.name] = { }
        raw_data[m.name][m.participant_name] = [ ] unless m.participant_name.blank?
        raw_data[m.name][m.author_name] = [ ] unless m.author_name.blank?

        # we want the participant's eval of the author as author
        if !m.author_name.blank? && !m.participant_eval.nil? && !m.participant_eval.empty?
          self.assignment_participations.
               select {|ap| ap.position == m.position }.
               each do |ap|
            raw_data[m.name][m.author_name] << tag_responses(m.participant_eval,ap.participant_eval)
          end
        end

        # and the other author's evals of the author as participant
        if !m.participant_name.blank? && !m.author_eval.nil? && !m.author_eval.empty?
          m.assignment_participations.each do |ap|
            raw_data[m.name][m.participant_name] << tag_responses(m.author_eval,ap.author_eval)
          end
        end
      end
    end

    if !self.author_eval.nil?
      raw_data['self'] = {
        'author' => tag_responses(self.assignment.author_eval,self.author_eval)
      }
    end

    self.scores = self.assignment.calculate_scores(raw_data)
    self.save
    self.scores
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
