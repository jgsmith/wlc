class AddAssignmentNames < ActiveRecord::Migration
  def self.up
    add_column :assignments, :name, :string
  end

  def self.down
    drop_column :assignments, :name
  end
end
