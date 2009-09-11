class CreateTransitionDefs < ActiveRecord::Migration
  def self.up
    create_table :transition_defs do |t|
      t.references :from_state
      t.references :to_state
      t.text :process_fn
      t.text :validate_fn

      t.timestamps
    end
  end

  def self.down
    drop_table :transition_defs
  end
end
