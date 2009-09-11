class CreateSemesters < ActiveRecord::Migration
  def self.up
    create_table :semesters do |t|
      t.string :name
      t.datetime :utc_starts_at
      t.datetime :utc_ends_at
      t.string   :timezone, :default => 'America/Chicago'

      t.timestamps
    end
  end

  def self.down
    drop_table :semesters
  end
end
