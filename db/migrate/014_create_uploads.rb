class CreateUploads < ActiveRecord::Migration
  def self.up
    create_table :uploads do |t|
      t.references :user
      t.references :holder, :polymorphic => { :default => 'AssignmentParticipation' }
      t.string :filename
      t.integer :size
      t.string :content_type
      t.string :tag

      t.timestamps
    end
  end

  def self.down
    drop_table :uploads
  end
end
