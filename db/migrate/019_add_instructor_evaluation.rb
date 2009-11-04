class AddInstructorEvaluation < ActiveRecord::Migration
  def self.up
    add_column :assignment_submissions, :instructor_eval, :text
    add_column :assignment_submissions, :instructor_score, :float
    add_column :assignment_submissions, :final_trust, :float
  end

  def self.down
    remove_column :assignment_submissions, :instructor_score
    remove_column :assignment_submissions, :instructor_eval
    remove_column :assignment_submissions, :final_trust
  end
end
