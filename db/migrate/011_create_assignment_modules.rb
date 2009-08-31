class CreateAssignmentModules < ActiveRecord::Migration
  def self.up
    create_table :assignment_modules do |t|
      t.references :assignment
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
  end

  def self.down
    drop_table :assignment_modules
  end
end
