class CreateTempFiles < ActiveRecord::Migration
  def self.up
    create_table :temp_files do |t|
      t.references :holder, :polymorphic => { :default => 'AssignmentParticipati
on' }
      t.string :filename
      t.integer :size
      t.string :content_type

      t.timestamps
    end
  end

  def self.down
    drop_table :temp_files
  end
end

