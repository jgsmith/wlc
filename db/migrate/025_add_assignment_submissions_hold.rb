class AddAssignmentSubmissionsHold < ActiveRecord::Migration
  def self.up
    add_column :assignment_submissions, :on_hold, :boolean
  end

  def self.down
    drop_column :assignment_submissions, :on_hold
  end
end

