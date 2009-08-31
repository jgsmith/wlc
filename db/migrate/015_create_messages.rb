class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.references :assignment_participation
      t.references :user
      t.string :subject
      t.text :content
      t.boolean :is_read

      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
