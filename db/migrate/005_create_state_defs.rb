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

    StateDef.create :name => 'start', :module_def_id => 1,
      :pre_fn => '',
      :post_fn => '',
      :view_text => 'Upload your submission to establish your participation in this assignment.',
      :view_form => {
        :items => [
          { :inputType => 'file',
            :xtype => 'field',
            :name => 'upload',
            :fieldLabel => 'Submission',
          }
        ],
        :submit => 'Upload Submission',
      }

    StateDef.create :name => 'submitted', :module_def_id => 1,
      :pre_fn => '',
      :post_fn => '',
      :view_text => 'You have uploaded your submission.  You may replace it by uploading another file now.',
      :view_form => {
        :items => [
          { :inputType => 'file',
            :xtype => 'field',
            :name => 'upload',
            :fieldLabel => 'Submission',
          }
        ],
        :submit => 'Replace Submission',
      }
  end

  def self.down
    drop_table :state_defs
  end
end
