class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table :courses do |t|
      t.string :name
      t.references :user
      t.references :semester
      t.text :description
      t.string :timezone, :default => 'America/Chicago'

      t.timestamps
    end
  end

  def self.down
    drop_table :courses
  end
end
