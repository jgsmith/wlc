class CreateStateDefs < ActiveRecord::Migration
  def self.up
    create_table :state_defs do |t|
      t.string :name
      t.references :module_def
      t.text :pre_fn
      t.text :post_fn
      t.text :view_text
      t.text :view_form

      t.timestamps
    end
  end

  def self.down
    drop_table :state_defs
  end
end
