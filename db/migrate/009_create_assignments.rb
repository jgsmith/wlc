class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.references :course
      t.references :assignment_template
      t.integer    :position
      t.datetime :starts_at

      t.timestamps
    end

    Assignment.create :course_id => 1, :starts_at => Time.now - 8*24*60*60,
      :assignment_template_id => 1, :position => 1

    Assignment.create :course_id => 1, :starts_at => '2009-09-21 00:00:00', :position => 2
  end

  def self.down
    drop_table :assignments
  end
end
