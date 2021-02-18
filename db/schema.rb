# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_02_131003) do

  create_table "answers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "response_id"
    t.integer "question_id"
    t.text "text_answer"
    t.date "date_answer"
    t.time "time_answer"
    t.decimal "decimal_answer", precision: 65, scale: 15
    t.integer "integer_answer"
    t.string "choice_answer"
    t.string "raw_answer"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["response_id"], name: "index_answers_on_response_id"
  end

  create_table "batch_files", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "survey_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.string "status"
    t.text "message"
    t.integer "record_count"
    t.string "summary_report_path"
    t.string "detail_report_path"
    t.integer "year_of_registration"
    t.integer "clinic_id"
    t.index ["survey_id"], name: "index_batch_files_on_survey_id"
  end

  create_table "capturesystem_surveys", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "capturesystem_id"
    t.integer "survey_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["capturesystem_id", "survey_id"], name: "index_capturesystem_surveys_on_capturesystem_id_and_survey_id", unique: true
    t.index ["capturesystem_id"], name: "index_capturesystem_surveys_on_capturesystem_id"
    t.index ["survey_id", "capturesystem_id"], name: "index_capturesystem_surveys_on_survey_id_and_capturesystem_id", unique: true
    t.index ["survey_id"], name: "index_capturesystem_surveys_on_survey_id"
  end

  create_table "capturesystem_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "capturesystem_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "access_status"
    t.index ["capturesystem_id", "user_id"], name: "index_capturesystem_users_on_capturesystem_id_and_user_id", unique: true
    t.index ["capturesystem_id"], name: "index_capturesystem_users_on_capturesystem_id"
    t.index ["user_id", "capturesystem_id"], name: "index_capturesystem_users_on_user_id_and_capturesystem_id", unique: true
    t.index ["user_id"], name: "index_capturesystem_users_on_user_id"
  end

  create_table "capturesystems", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "base_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clinic_allocations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "clinic_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clinic_id"], name: "index_clinic_allocations_on_clinic_id"
    t.index ["user_id"], name: "index_clinic_allocations_on_user_id"
  end

  create_table "clinics", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "state"
    t.string "unit_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "unit_code"
    t.integer "site_code"
    t.string "site_name"
    t.boolean "active", default: true, null: false
    t.integer "capturesystem_id"
    t.index ["capturesystem_id", "unit_code", "site_code"], name: "index_clinics_on_capturesystem_id_and_unit_code_and_site_code", unique: true
  end

  create_table "configuration_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "configuration_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_configuration_items_on_name", unique: true
  end

  create_table "cross_question_validations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "question_id"
    t.integer "related_question_id"
    t.string "rule"
    t.text "error_message"
    t.string "operator"
    t.string "constant"
    t.string "set_operator"
    t.string "set"
    t.string "conditional_operator"
    t.string "conditional_constant"
    t.string "conditional_set_operator"
    t.string "conditional_set"
    t.string "related_question_ids"
    t.text "comments"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "question_options", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "question_id"
    t.string "option_value"
    t.string "label"
    t.text "hint_text"
    t.integer "option_order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["question_id"], name: "index_question_options_on_question_id"
  end

  create_table "questions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "section_id"
    t.string "question"
    t.string "question_type"
    t.integer "question_order"
    t.string "code"
    t.text "description"
    t.text "guide_for_use"
    t.decimal "number_min", precision: 65, scale: 15
    t.decimal "number_max", precision: 65, scale: 15
    t.integer "number_unknown"
    t.integer "string_min"
    t.integer "string_max"
    t.boolean "mandatory"
    t.boolean "multiple", default: false
    t.string "multi_name"
    t.integer "group_number"
    t.integer "order_within_group"
  end

  create_table "responses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "survey_id"
    t.integer "user_id"
    t.string "cycle_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "clinic_id"
    t.string "submitted_status"
    t.integer "batch_file_id"
    t.integer "year_of_registration"
    t.string "validation_status"
    t.index ["survey_id", "year_of_registration", "cycle_id"], name: "index_response_for_upload_records", unique: true
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "survey_id"
    t.integer "section_order"
    t.string "name"
  end

  create_table "survey_configurations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "survey_id"
    t.integer "start_year_of_treatment"
    t.integer "end_year_of_treatment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "year_range_type", default: "C"
    t.index ["survey_id"], name: "index_survey_configurations_on_survey_id"
  end

  create_table "surveys", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", limit: 128, default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0
    t.datetime "locked_at"
    t.string "first_name"
    t.string "last_name"
    t.string "status"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "allocated_unit_code"
    t.string "unlock_token"
    t.string "session_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

end
