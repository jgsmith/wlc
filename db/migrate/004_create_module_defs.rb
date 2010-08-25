class CreateModuleDefs < ActiveRecord::Migration
  def self.up
    create_table :module_defs do |t|
      t.string :name
      t.text :definition
      t.text :compiled_xsm
      t.text :instructions
      t.text :description
      t.text :show_info
      t.text :params
      t.boolean :is_evaluative
      t.string :download_filename_prefix

      t.timestamps
    end
  end

  def self.down
    drop_table :module_defs
  end
end
