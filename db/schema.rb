# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 23) do

  create_table "assignment_modules", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "module_def_id"
    t.string   "name"
    t.integer  "position"
    t.string   "tag"
    t.integer  "number_participants"
    t.integer  "duration"
    t.text     "instructions"
    t.boolean  "has_messaging"
    t.string   "participant_name"
    t.string   "author_name"
    t.text     "old_author_eval"
    t.text     "old_participant_eval"
    t.text     "params"
    t.string   "download_filename_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_rubric_id"
    t.integer  "participant_rubric_id"
  end

  create_table "assignment_participations", :force => true do |t|
    t.integer  "assignment_submission_id"
    t.integer  "user_id"
    t.integer  "state_def_id"
    t.string   "tag"
    t.text     "context"
    t.text     "author_eval"
    t.text     "participant_eval"
    t.string   "participant_name"
    t.string   "author_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "author_eval_score"
    t.float    "participant_eval_score"
  end

  create_table "assignment_submissions", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.text     "author_eval"
    t.text     "scores"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "author_eval_score"
    t.float    "score"
    t.float    "trust"
    t.text     "instructor_eval"
    t.float    "instructor_score"
    t.float    "final_trust"
  end

  create_table "assignment_template_modules", :force => true do |t|
    t.integer  "assignment_template_id"
    t.integer  "module_def_id"
    t.string   "name"
    t.integer  "position"
    t.integer  "number_participants"
    t.integer  "duration"
    t.text     "instructions"
    t.boolean  "has_messaging"
    t.string   "participant_name"
    t.string   "author_name"
    t.text     "old_author_eval"
    t.text     "old_participant_eval"
    t.text     "params"
    t.string   "download_filename_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_rubric_id"
    t.integer  "participant_rubric_id"
  end

  create_table "assignment_templates", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.integer  "eval_duration"
    t.integer  "number_evaluations"
    t.string   "eval_name"
    t.string   "author_name"
    t.text     "old_author_eval"
    t.text     "old_participant_eval"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_rubric_id"
    t.integer  "participant_rubric_id"
    t.boolean  "calculate_trust"
    t.boolean  "use_trust"
    t.boolean  "trust_uses_self_eval"
    t.integer  "trust_mean"
    t.text     "trust_fn"
  end

  create_table "assignments", :force => true do |t|
    t.integer  "course_id"
    t.integer  "position"
    t.integer  "eval_duration"
    t.integer  "number_evaluations"
    t.boolean  "late_work_acceptable",  :default => false, :null => false
    t.string   "eval_name"
    t.string   "author_name"
    t.string   "eval_tag"
    t.text     "old_author_eval"
    t.text     "old_participant_eval"
    t.text     "calculate_score_fn"
    t.text     "score_view"
    t.datetime "utc_starts_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_rubric_id"
    t.integer  "participant_rubric_id"
    t.boolean  "scores_final"
    t.boolean  "calculate_trust"
    t.boolean  "use_trust"
    t.boolean  "trust_uses_self_eval"
    t.integer  "trust_mean"
    t.text     "trust_fn"
    t.boolean  "scores_calculated"
    t.text     "xml_definition"
  end

  create_table "course_participants", :force => true do |t|
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "course_participants", ["course_id", "user_id"], :name => "course_participants_course_id_user_id", :unique => true

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "semester_id"
    t.text     "description"
    t.string   "timezone",    :default => "America/Chicago"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.integer  "assignment_participation_id"
    t.integer  "user_id"
    t.string   "subject"
    t.text     "content"
    t.boolean  "is_read"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "module_defs", :force => true do |t|
    t.string   "name"
    t.text     "init_fn"
    t.text     "instructions"
    t.text     "description"
    t.text     "show_info"
    t.text     "params"
    t.boolean  "is_evaluative"
    t.string   "download_filename_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "xml_definition"
  end

  create_table "prompts", :force => true do |t|
    t.integer  "rubric_id"
    t.integer  "position"
    t.string   "prompt"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "responses", :force => true do |t|
    t.integer  "prompt_id"
    t.integer  "position"
    t.integer  "score"
    t.string   "response"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rubrics", :force => true do |t|
    t.string   "name"
    t.text     "instructions"
    t.text     "calculate_fn"
    t.float    "minimum"
    t.float    "floor"
    t.float    "maximum"
    t.float    "ceiling"
    t.boolean  "inclusive_minimum"
    t.boolean  "inclusive_maximum"
    t.boolean  "use_trust"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
  end

  create_table "scores", :force => true do |t|
    t.integer "assignment_id"
    t.integer "user_id"
    t.string  "tag"
    t.float   "author_score"
    t.float   "participant_score"
  end

  create_table "semesters", :force => true do |t|
    t.string   "name"
    t.datetime "utc_starts_at"
    t.datetime "utc_ends_at"
    t.string   "timezone",      :default => "America/Chicago"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "state_defs", :force => true do |t|
    t.string   "name"
    t.integer  "module_def_id"
    t.text     "pre_fn"
    t.text     "post_fn"
    t.text     "view_text"
    t.text     "view_form"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "view"
  end

  create_table "temp_files", :force => true do |t|
    t.integer  "holder_id"
    t.string   "holder_type",  :default => "AssignmentParticipati\non"
    t.string   "filename"
    t.integer  "size"
    t.string   "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transition_defs", :force => true do |t|
    t.integer  "from_state_id"
    t.integer  "to_state_id"
    t.text     "process_fn"
    t.text     "validate_fn"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "uploads", :force => true do |t|
    t.integer  "user_id"
    t.integer  "holder_id"
    t.string   "holder_type",  :default => "AssignmentParticipation"
    t.string   "filename"
    t.integer  "size"
    t.string   "content_type"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "uin",                       :limit => 9
    t.string   "email"
    t.string   "name"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.boolean  "is_admin",                                :default => false
  end

  add_index "users", ["uin"], :name => "users_uin", :unique => true

end
