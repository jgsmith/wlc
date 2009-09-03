class CreateAssignmentTemplates < ActiveRecord::Migration
  def self.up
    create_table :assignment_templates do |t|
      t.references :user
      t.string :name
      t.text :description
      t.integer :eval_duration
      t.integer :number_evaluations
      t.string  :eval_name
      t.string     :author_name
      t.text       :author_eval
      t.text       :participant_eval


      t.timestamps
    end

    AssignmentTemplate.create :user_id => 1, :name => 'Simple',
      :description => "Dan's Assignment"
  end

  def self.down
    drop_table :assignment_templates
  end
end
