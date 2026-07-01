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

ActiveRecord::Schema[8.1].define(version: 2025_07_01_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_tasks", force: :cascade do |t|
    t.string "agent_type", null: false
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.jsonb "input", default: {}, null: false
    t.jsonb "output", default: {}, null: false
    t.bigint "parent_task_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["parent_task_id"], name: "index_agent_tasks_on_parent_task_id"
    t.index ["user_id", "agent_type", "status"], name: "index_agent_tasks_on_user_id_and_agent_type_and_status"
    t.index ["user_id"], name: "index_agent_tasks_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.string "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.string "period", default: "monthly", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id", "category_id", "period"], name: "index_budgets_on_user_id_and_category_id_and_period", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.string "slug", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["user_id", "slug"], name: "index_categories_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "conversation_messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_session_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_session_id"], name: "index_conversation_messages_on_conversation_session_id"
  end

  create_table "conversation_sessions", force: :cascade do |t|
    t.string "channel", default: "whatsapp", null: false
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "state", default: "idle", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "channel"], name: "index_conversation_sessions_on_user_id_and_channel"
    t.index ["user_id"], name: "index_conversation_sessions_on_user_id"
  end

  create_table "insights", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "dismissed_at"
    t.string "insight_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "severity", default: "info", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "insight_type"], name: "index_insights_on_user_id_and_insight_type"
    t.index ["user_id"], name: "index_insights_on_user_id"
  end

  create_table "merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "normalized_name", null: false
    t.datetime "updated_at", null: false
    t.index ["normalized_name"], name: "index_merchants_on_normalized_name", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.string "channel", default: "whatsapp", null: false
    t.datetime "created_at", null: false
    t.string "notification_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.string "status", default: "pending", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "status", "scheduled_at"], name: "index_notifications_on_user_id_and_status_and_scheduled_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "statement_imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "imported_count", default: 0, null: false
    t.integer "processed_count", default: 0, null: false
    t.string "source"
    t.string "status", default: "pending", null: false
    t.integer "total_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_statement_imports_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_statement_imports_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.string "description"
    t.string "external_id"
    t.string "fingerprint"
    t.bigint "merchant_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "payment_method", default: "upi", null: false
    t.bigint "related_transaction_id"
    t.string "source", default: "upi", null: false
    t.string "status", default: "completed", null: false
    t.datetime "transaction_at", null: false
    t.datetime "updated_at", null: false
    t.string "upi_reference"
    t.uuid "user_id", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["external_id"], name: "index_transactions_on_external_id"
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
    t.index ["metadata"], name: "index_transactions_on_metadata", using: :gin
    t.index ["related_transaction_id"], name: "index_transactions_on_related_transaction_id"
    t.index ["user_id", "fingerprint"], name: "index_transactions_on_user_id_and_fingerprint", unique: true, where: "(fingerprint IS NOT NULL)"
    t.index ["user_id", "transaction_at"], name: "index_transactions_on_user_id_and_transaction_at"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "upi_ids", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "upi_id", null: false
    t.uuid "user_id", null: false
    t.datetime "verified_at"
    t.index ["user_id", "upi_id"], name: "index_upi_ids_on_user_id_and_upi_id", unique: true
    t.index ["user_id"], name: "index_upi_ids_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "mobile_number", null: false
    t.bigint "monthly_budget_cents"
    t.string "name", null: false
    t.datetime "onboarding_completed_at"
    t.string "password_digest", null: false
    t.string "preferred_currency", default: "INR", null: false
    t.string "sync_token"
    t.string "timezone", default: "Asia/Kolkata", null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp_number", null: false
    t.boolean "whatsapp_verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["sync_token"], name: "index_users_on_sync_token", unique: true
    t.index ["whatsapp_number"], name: "index_users_on_whatsapp_number", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agent_tasks", "agent_tasks", column: "parent_task_id"
  add_foreign_key "agent_tasks", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "conversation_messages", "conversation_sessions"
  add_foreign_key "conversation_sessions", "users"
  add_foreign_key "insights", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "statement_imports", "users"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "merchants"
  add_foreign_key "transactions", "transactions", column: "related_transaction_id"
  add_foreign_key "transactions", "users"
  add_foreign_key "upi_ids", "users"
end
