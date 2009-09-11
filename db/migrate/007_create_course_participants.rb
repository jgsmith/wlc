class CreateCourseParticipants < ActiveRecord::Migration
  def self.up
    create_table :course_participants do |t|
      t.references :course
      t.references :user
      t.integer :level

      t.timestamps
    end
  end

  def self.down
    drop_table :course_participants
  end
end
