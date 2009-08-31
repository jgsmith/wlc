class CreateSemesters < ActiveRecord::Migration
  def self.up
    create_table :semesters do |t|
      t.string :name
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end

    Semester.create :name => 'Fall 2009', :starts_at => '2009-08-25 00:00:00', :ends_at => '2009-12-20 00:00:00'
  end

  def self.down
    drop_table :semesters
  end
end
