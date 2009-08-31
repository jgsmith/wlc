class CreateModuleDefs < ActiveRecord::Migration
  def self.up
    create_table :module_defs do |t|
      t.string :name
      t.text :init_fn
      t.text :instructions
      t.text :description
      t.text :show_info
      t.boolean :is_evaluative
      t.string :download_filename_prefix

      t.timestamps
    end

    ModuleDef.create :name => 'Simple Submission',
                     :instructions => 'Instructions go here.',
                     :description => 'Description for instructors.',
                     :download_filename_prefix => 'original',
                     :show_info => '
       {% if participation.uploads.size > 0 %}
          <div class="participation-uploads">
          {% for upload in participation.uploads %}
            <div class="participation-upload">
              {% if upload.user == user %}
                Filename: {{ upload.filename }}
              {% else %}
                <a href="{{ upload.url }}">{{ upload.download_name }}</a>
              {% endif %}
              ({{ upload.size }} bytes)
            </div>
          {% endfor %}
          </div>
        {% endif %}
                     ',
                     :init_fn => '
                       if has_attached_upload("upload") then
                         goto("submitted")
                       else
                         goto("start")
                       end
                     ',
                     :is_evaluative => false
  end

  def self.down
    drop_table :module_defs
  end
end
