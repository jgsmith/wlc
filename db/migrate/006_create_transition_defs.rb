class CreateTransitionDefs < ActiveRecord::Migration
  def self.up
    create_table :transition_defs do |t|
      t.references :from_state
      t.references :to_state
      t.text :process_fn
      t.text :validate_fn

      t.timestamps
    end

    TransitionDef.create :from_state_id => 1, :to_state_id => 2,
      :validate_fn => '
        if has_upload("upload") then
          return {
            score = 1.0,
            valid = { }
          }
        else
          return {
            score = 0.0,
            valid = { },
            missing = { "upload" }
          }
        end
      ',
      :process_fn => 'attach_upload("upload")'

    TransitionDef.create :from_state_id => 2, :to_state_id => 1,
      :validate_fn => '
        if has_upload("upload") then
          return {
            score = 1.0,
            valid = { }
          }
        else
          return {
            score = 0.0,
            valid = { },
            missing = { "upload" }
          }
        end
      ',
      :process_fn => '
        attach_upload("upload")
        goto("submitted")
      '
  end

  def self.down
    drop_table :transition_defs
  end
end
