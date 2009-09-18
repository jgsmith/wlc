class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.references :course
      t.integer    :position
      t.integer    :eval_duration
      t.integer    :number_evaluations
      t.boolean    :late_work_acceptable, :null => false, :default => false
      t.string     :eval_name
      t.string     :author_name
      t.string     :eval_tag
      t.text       :author_eval
      t.text       :participant_eval
      t.text       :calculate_score_fn
      t.text       :score_view
      t.datetime   :utc_starts_at

      t.timestamps
    end
  end

  def self.down
    drop_table :assignments
  end
end
