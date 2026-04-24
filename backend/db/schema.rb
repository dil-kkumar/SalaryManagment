# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_24_000003) do
  create_table "audit_logs", force: :cascade do |t|
    t.string "auditable_type", null: false
    t.integer "auditable_id", null: false
    t.string "action", null: false
    t.text "changed_data"
    t.string "user_ip"
    t.string "user_agent"
    t.string "user_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
  end

  create_table "country_custom_fields", force: :cascade do |t|
    t.string "country", null: false
    t.string "field_key", null: false
    t.string "label", null: false
    t.string "field_type", null: false
    t.string "placeholder"
    t.boolean "required", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country", "field_key"], name: "index_country_custom_fields_on_country_and_field_key", unique: true
    t.index ["country"], name: "index_country_custom_fields_on_country"
  end

  create_table "employees", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "job_title", null: false
    t.string "department", null: false
    t.string "country", null: false
    t.decimal "salary", precision: 12, scale: 2, null: false
    t.string "employment_type", default: "full-time", null: false
    t.date "hire_date", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_fields", default: "{}", null: false
    t.string "employee_id", limit: 20, null: false
    t.index ["country", "job_title"], name: "ix_employees_country_job_title"
    t.index ["country"], name: "index_employees_on_country"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_id"], name: "index_employees_on_employee_id", unique: true
    t.index ["job_title"], name: "index_employees_on_job_title"
    t.index ["status"], name: "index_employees_on_status"
  end

end
