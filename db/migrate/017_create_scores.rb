class CreateScores < ActiveRecord::Migration
  def self.up
    create_table :scores do |t|
      t.references :assignment
      t.references :user
      t.string     :tag
      t.float      :author_score
      t.float      :participant_score
    end
  end

  def self.down
    drop_table :scores
  end
end
