class CreateAssignmentParticipations < ActiveRecord::Migration
  def self.up
    create_table :assignment_participations do |t|
      t.references :assignment_submission
      t.references :user
      t.references :state_def
      t.integer    :position
      t.text :context
      t.text :author_eval
      t.text :participant_eval
      t.string :participant_name
      t.string :author_name

      t.timestamps
    end
  end

  def self.down
    drop_table :assignment_participations
  end
end
