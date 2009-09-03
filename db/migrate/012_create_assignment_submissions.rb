class CreateAssignmentSubmissions < ActiveRecord::Migration
  def self.up
    create_table :assignment_submissions do |t|
      t.references :assignment
      t.references :user
      t.text       :author_eval

      t.timestamps
    end

    AssignmentSubmission.create :user_id => 3, :assignment_id => 1
    AssignmentSubmission.create :user_id => 4, :assignment_id => 1
  end

  def self.down
    drop_table :assignment_submissions
  end
end
