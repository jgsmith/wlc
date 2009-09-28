namespace :db do
  namespace :schema do
    task :load do

      ###
      ### ModuleDef
      ###
      module_defs = { }

      module_defs[:simple_submission] = ModuleDef.create :name => 'Simple Submission',
        :instructions => '',
        :description => '',
        :download_filename_prefix => 'original',
        :params => {
          :purpose => {
             :fieldLabel => 'Purpose for upload',
             :inputType => 'textfield',
             :emptyText => 'to establish your participation in this assignment'
          },
          :submission_name => {
             :fieldLabel => 'Name of submission',
             :inputType => 'textfield',
             :emptyText => 'submission'
          },
        },
        :show_info => %{
{% if participation.uploads.size > 0 %}
  <div class="participation-uploads">
    {% for upload in participation.uploads %}
      <div class="participation-upload">
        {% if upload.user.id == user.id %}
          Your file, "{{ upload.filename }}," is available as
          <a href="{{ upload.url }}">{{ upload.download_name }}</a>.
        {% else %}
          <a href="{{ upload.url }}">{{ upload.download_name }}</a>
        {% endif %}
        ({{ upload.size }} bytes)
      </div>
   {% endfor %}
 </div>
{% endif %}},
        :init_fn => %{
if has_attached_upload("upload") then
  goto("submitted")
else
  goto("start")
end     },
        :is_evaluative => false

      module_defs[:simple_critique] = ModuleDef.create :name => 'Simple Critique',
        :instructions => '',
        :description => '',
        :download_filename_prefix => 'critique',
        :show_info => %{
{% if participation.uploads.size > 0 %}
  <div class="participation-uploads">
    {% for upload in participation.uploads %}
      <div class="participation-upload">
        {% if upload.user.id == user.id %}
          Your file, "{{ upload.filename }}," is available as
          <a href="{{ upload.url }}">{{ upload.download_name }}</a>.
        {% else %}
          <a href="{{ upload.url }}">{{ upload.download_name }}</a>
        {% endif %}
        ({{ upload.size }} bytes)
      </div>
    {% endfor %}
  </div>
{% endif %} },
        :init_fn => %{
if has_attached_upload("upload") then
  goto("submitted")
else
  goto("start")
end     },
        :is_evaluative => true

      module_defs[:genre_submission] = ModuleDef.create :name => 'Genre Submission',
        :instructions => '',
        :description => '',
        :download_filename_prefix => 'original',
        :params => {
          :purpose => {
             :label => 'Purpose for upload',
             :type => 'string',
             :empty => 'to establish your participation in this assignment'
          },
          :submission_name => {
             :label => 'Name of submission',
             :type => 'string',
             :empty => 'submission'
          },
          :genres => {
             :label => "Genres",
             :type => 'grid',
             :columns => ['Label', 'Value']
          },
        },
        :show_info => %{
{% if participation.uploads.size > 0 %}
  <div class="participation-uploads">
    {% for upload in participation.uploads %}
      <div class="participation-upload">
        {% if upload.user.id == user.id %}
          Your file, "{{ upload.filename }}," is available as
          <a href="{{ upload.url }}">{{ upload.download_name }}</a>.
        {% else %}
          <a href="{{ upload.url }}">{{ upload.download_name }}</a>
        {% endif %}
        ({{ upload.size }} bytes)
      </div>
   {% endfor %}
 </div>
{% endif %}},
        :init_fn => %{
if has_attached_upload("upload") then
  goto("submitted")
else
  goto("start")
end     },
        :is_evaluative => false
      ###
      ### StateDef
      ###

      state_defs = { }

        ## Simple Submission
      state_defs[:simple_submission] = { }

      state_defs[:simple_submission][:start] = StateDef.create :name => 'start',
        :module_def_id => module_defs[:simple_submission].id,
        :pre_fn => '',
        :post_fn => '',
        :view_text => %{
Upload your {{ params.submission_name }} {{ params.purpose }}.

You have {{ dates.module.ends_at }} to upload your file.
},
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

      state_defs[:simple_submission][:submitted] = StateDef.create :name => 'submitted',
        :module_def_id => module_defs[:simple_submission].id,
        :pre_fn => '',
        :post_fn => '',
        :view_text => %{
You have uploaded your {{ params.submission_name }}.
You may replace it by uploading another file now.

You have {{ dates.module.ends_at }} to upload your file.
},
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
                

        ## Simple Critique
      state_defs[:simple_critique] = { }

      state_defs[:simple_critique][:start] = StateDef.create :name => 'start',
        :module_def_id => module_defs[:simple_critique].id,
        :pre_fn => '',
        :post_fn => '',
        :view_text => %{
Upload your revised submission for this assignment.
          
You have {{ dates.module.ends_at }} to upload your file.
},
        :view_form => {  
          :items => [
            { :inputType => 'file',
              :xtype => 'field',
              :name => 'upload',
              :fieldLabel => 'Critique',
            }
          ],
          :submit => 'Upload Critique',
        }

      
    end
  end
end

