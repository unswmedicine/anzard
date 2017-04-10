# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170309044117) do

  create_table "answers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "response_id"
    t.integer "question_id"
    t.text    "text_answer",    limit: 65535
    t.date    "date_answer"
    t.time    "time_answer"
    t.decimal "decimal_answer",               precision: 65, scale: 15
    t.integer "integer_answer"
    t.string  "choice_answer"
    t.string  "raw_answer"
    t.index ["response_id"], name: "index_answers_on_response_id", using: :btree
  end

  create_table "batch_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "survey_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "status"
    t.integer  "hospital_id"
    t.string   "message"
    t.integer  "record_count"
    t.string   "summary_report_path"
    t.string   "detail_report_path"
    t.integer  "year_of_registration"
    t.index ["survey_id"], name: "index_batch_files_on_survey_id", using: :btree
  end

  create_table "configuration_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "configuration_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cross_question_validations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "question_id"
    t.integer "related_question_id"
    t.string  "rule"
    t.string  "error_message"
    t.string  "operator"
    t.decimal "constant",                               precision: 65, scale: 15
    t.string  "set_operator"
    t.string  "set"
    t.string  "conditional_operator"
    t.decimal "conditional_constant",                   precision: 65, scale: 15
    t.string  "conditional_set_operator"
    t.string  "conditional_set"
    t.string  "related_question_ids"
    t.text    "comments",                 limit: 65535
  end

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "priority",                 default: 0
    t.integer  "attempts",                 default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "hospitals", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "state"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "unit"
    t.integer  "site"
    t.string   "site_name"
  end

  create_table "question_options", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "question_id"
    t.string   "option_value"
    t.string   "label"
    t.text     "hint_text",    limit: 65535
    t.integer  "option_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["question_id"], name: "index_question_options_on_question_id", using: :btree
  end

  create_table "questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "section_id"
    t.string  "question"
    t.string  "question_type"
    t.integer "question_order"
    t.string  "code"
    t.text    "description",        limit: 65535
    t.text    "guide_for_use",      limit: 65535
    t.decimal "number_min",                       precision: 65, scale: 15
    t.decimal "number_max",                       precision: 65, scale: 15
    t.integer "number_unknown"
    t.integer "string_min"
    t.integer "string_max"
    t.boolean "mandatory"
    t.boolean "multiple",                                                   default: false
    t.string  "multi_name"
    t.integer "group_number"
    t.integer "order_within_group"
  end

  create_table "responses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "survey_id"
    t.integer  "user_id"
    t.string   "baby_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hospital_id"
    t.string   "submitted_status"
    t.integer  "batch_file_id"
    t.integer  "year_of_registration"
    t.string   "validation_status"
  end

  create_table "roles", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "survey_id"
    t.integer "section_order"
    t.string  "name"
  end

  create_table "supplementary_files", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "multi_name"
    t.integer  "batch_file_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["batch_file_id"], name: "index_supplementary_files_on_batch_file_id", using: :btree
  end

  create_table "surveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "email",                              default: "", null: false
    t.string   "encrypted_password",     limit: 128, default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                    default: 0
    t.datetime "locked_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "status"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hospital_id"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
