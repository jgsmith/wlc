class CreateAssignmentTemplateModules < ActiveRecord::Migration
  def self.up
    create_table :assignment_template_modules do |t|
      t.references :assignment_template
      t.references :module_def
      t.string  :name
      t.integer :position
      t.integer :number_participants
      t.integer :duration
      t.text :instructions
      t.boolean :has_messaging
      t.string :participant_name
      t.string :author_name
      t.text :author_eval
      t.text :participant_eval
      t.string :download_filename_prefix

      t.timestamps
    end

    AssignmentTemplateModule.create :assignment_template_id => 1,
      :module_def_id => 1,
      :position => 1, :number_participants => 1, :duration => 7*24*60*60,
      :instructions => 'Assignment template module instructions.',
      :has_messaging => false
    AssignmentTemplateModule.create :assignment_template_id => 1,
      :module_def_id => nil,
      :position => 2, :number_participants => 2, :duration => 7*24*60*60,
      :instructions => 'Review the submission and provide feedback.',
      :has_messaging => true,
      :author_name => 'Author', :participant_name => 'Reviewer',
      :author_eval => { 
        :instructions => %{
          This evaluation concerns your experience with the given reviewer.
        },
        :prompts => [
          { :prompt => 'What is your favorite pet?',
            :responses => [
              { :response => 'A dog', :score => 0 },
              { :response => 'A cat!', :score => 1 },
              { :response => 'A badger', :score => 2 }
            ]
          },
          { :prompt => 'What is the moon made of?',
            :responses => [
              { :response => 'Green Cheese', :score => 0 },
              { :response => 'Red Cheese', :score => 1 },
              { :response => 'Blue Cheese', :score => 2 },
            ]
          }
        ]
      },
      :participant_eval => { }
  end

  def self.down
    drop_table :assignment_template_modules
  end
end
