class CreateAssignmentSubmissions < ActiveRecord::Migration
  def self.up
    create_table :assignment_submissions do |t|
      t.references :assignment
      t.references :user
      t.text       :author_eval
      t.text       :scores

      t.timestamps
    end
  end

  def self.down
    drop_table :assignment_submissions
  end
end
