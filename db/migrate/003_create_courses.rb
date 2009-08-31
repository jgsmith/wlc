class CreateCourses < ActiveRecord::Migration
  def self.up
    create_table :courses do |t|
      t.string :name
      t.references :user
      t.references :semester
      t.text :description

      t.timestamps
    end

    Course.create :name => 'Intro to Psyc', :user_id => 2, :semester_id => 1, :description => 'description goes here'
  end

  def self.down
    drop_table :courses
  end
end
