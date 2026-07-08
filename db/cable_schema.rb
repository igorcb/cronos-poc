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

ActiveRecord::Schema[8.1].define(version: 2026_07_08_112412) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.decimal "hourly_rate", precision: 10, scale: 2, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["active"], name: "index_companies_on_active"
    t.index ["user_id", "active"], name: "index_companies_on_user_id_and_active"
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "idle_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.time "end_time", null: false
    t.decimal "hours", precision: 10, scale: 2, null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "work_date", null: false
    t.index ["user_id", "work_date"], name: "index_idle_periods_on_user_id_and_work_date"
    t.index ["user_id"], name: "index_idle_periods_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["company_id"], name: "index_projects_on_company_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "task_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.time "end_time", null: false
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "hours_worked", precision: 10, scale: 2, null: false
    t.time "start_time", null: false
    t.string "status", default: "pending", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "value", precision: 10, scale: 2
    t.date "work_date", default: -> { "CURRENT_DATE" }
    t.index ["status"], name: "index_task_items_on_status"
    t.index ["task_id", "created_at"], name: "index_task_items_on_task_id_and_created_at"
    t.index ["task_id"], name: "index_task_items_on_task_id"
    t.index ["user_id", "work_date"], name: "index_task_items_on_user_id_and_work_date"
    t.index ["user_id"], name: "index_task_items_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "code"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.decimal "delivered_value", precision: 10, scale: 2
    t.date "delivery_date"
    t.date "end_date"
    t.decimal "estimated_hours", precision: 10, scale: 2, null: false
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.bigint "project_id", null: false
    t.date "start_date", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "validated_hours", precision: 10, scale: 2
    t.index ["company_id", "project_id"], name: "index_tasks_on_company_id_and_project_id"
    t.index ["company_id"], name: "index_tasks_on_company_id"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["user_id", "start_date"], name: "index_tasks_on_user_id_and_start_date"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "google_uid"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "companies", "users"
  add_foreign_key "idle_periods", "users"
  add_foreign_key "projects", "companies"
  add_foreign_key "projects", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "task_items", "tasks"
  add_foreign_key "task_items", "users"
  add_foreign_key "tasks", "companies"
  add_foreign_key "tasks", "users"
end
