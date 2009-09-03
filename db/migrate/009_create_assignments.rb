class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.references :course
      t.references :assignment_template
      t.integer    :position
      t.integer    :eval_duration
      t.integer    :number_evaluations
      t.string     :eval_name
      t.string     :author_name
      t.text       :author_eval
      t.text       :participant_eval
      t.datetime   :starts_at

      t.timestamps
    end

    Assignment.create :course_id => 1, :starts_at => Time.now - 6*24*60*60,
      :assignment_template_id => 1, :position => 1, :eval_duration => 3*24*60*60, :eval_name => 'Evaluation',
      :author_name => 'Author', :number_evaluations => 1, 
      :author_eval => {
        :instructions => 'Know thyself!',
        :prompts => [ 
          { :prompt => 'What is your favorite color?',
            :responses => [
              { :response => 'Blue', :score => 0 },
              { :response => 'Red',  :score => 1 },
              { :response => 'Green', :score => 3 }
            ]
          }
        ]
      }

    Assignment.create :course_id => 1, :starts_at => '2009-09-21 00:00:00', :position => 2
  end

  def self.down
    drop_table :assignments
  end
end
