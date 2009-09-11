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

ActiveRecord::Schema.define(:version => 16) do

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
    t.text     "author_eval"
    t.text     "participant_eval"
    t.string   "download_filename_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
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
  end

  create_table "assignment_submissions", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.text     "author_eval"
    t.text     "scores"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.text     "author_eval"
    t.text     "participant_eval"
    t.string   "download_filename_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignment_templates", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.integer  "eval_duration"
    t.integer  "number_evaluations"
    t.string   "eval_name"
    t.string   "author_name"
    t.text     "author_eval"
    t.text     "participant_eval"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignments", :force => true do |t|
    t.integer  "course_id"
    t.integer  "assignment_template_id"
    t.integer  "position"
    t.integer  "eval_duration"
    t.integer  "number_evaluations"
    t.string   "eval_name"
    t.string   "author_name"
    t.string   "eval_tag"
    t.text     "author_eval"
    t.text     "participant_eval"
    t.text     "calculate_score_fn"
    t.text     "score_view"
    t.datetime "utc_starts_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_participants", :force => true do |t|
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.boolean  "is_evaluative"
    t.string   "download_filename_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "email"
    t.string   "name"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
  end

end
