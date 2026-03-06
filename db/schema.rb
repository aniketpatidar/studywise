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

ActiveRecord::Schema[8.0].define(version: 2026_03_07_005000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.bigint "chat_session_id", null: false
    t.string "role", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_session_id", "created_at"], name: "index_chat_messages_on_chat_session_id_and_created_at"
    t.index ["chat_session_id"], name: "index_chat_messages_on_chat_session_id"
  end

  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "material_id"
    t.string "mode", null: false
    t.string "subject_name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["material_id"], name: "index_chat_sessions_on_material_id"
    t.index ["slug"], name: "index_chat_sessions_on_slug", unique: true
    t.index ["user_id", "mode"], name: "index_chat_sessions_on_user_id_and_mode"
    t.index ["user_id"], name: "index_chat_sessions_on_user_id"
  end

  create_table "llm_events", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "material_id"
    t.string "provider", null: false
    t.string "model", null: false
    t.string "operation", null: false
    t.boolean "success", default: false, null: false
    t.integer "status_code"
    t.integer "latency_ms"
    t.integer "prompt_chars", default: 0, null: false
    t.integer "response_chars", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "prompt_preview"
    t.text "response_preview"
    t.index ["material_id", "created_at"], name: "index_llm_events_on_material_id_and_created_at"
    t.index ["material_id"], name: "index_llm_events_on_material_id"
    t.index ["user_id", "created_at"], name: "index_llm_events_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_llm_events_on_user_id"
  end

  create_table "material_chunks", force: :cascade do |t|
    t.bigint "material_id", null: false
    t.integer "sequence", null: false
    t.text "chunk_text", null: false
    t.text "summary"
    t.jsonb "embedding", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id", "sequence"], name: "index_material_chunks_on_material_id_and_sequence", unique: true
    t.index ["material_id"], name: "index_material_chunks_on_material_id"
  end

  create_table "materials", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "source_type", default: "text", null: false
    t.string "source_url"
    t.text "raw_text"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["slug"], name: "index_materials_on_slug", unique: true
    t.index ["source_type"], name: "index_materials_on_source_type"
    t.index ["status"], name: "index_materials_on_status"
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "material_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "generation_mode", default: "fallback", null: false
    t.string "share_token"
    t.boolean "shared_public", default: false, null: false
    t.string "idempotency_key"
    t.index ["created_at"], name: "index_notes_on_created_at"
    t.index ["material_id", "idempotency_key"], name: "index_notes_on_material_id_and_idempotency_key", unique: true
    t.index ["material_id"], name: "index_notes_on_material_id"
    t.index ["share_token"], name: "index_notes_on_share_token", unique: true
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "user_id", null: false
    t.integer "score", default: 0, null: false
    t.integer "total", default: 0, null: false
    t.jsonb "answers", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id", "user_id"], name: "index_quiz_attempts_on_quiz_id_and_user_id", unique: true
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.bigint "material_id", null: false
    t.string "title", null: false
    t.jsonb "questions", default: [], null: false
    t.string "generation_mode", default: "fallback", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "idempotency_key"
    t.index ["material_id", "idempotency_key"], name: "index_quizzes_on_material_id_and_idempotency_key", unique: true
    t.index ["material_id"], name: "index_quizzes_on_material_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.string "oauth_provider"
    t.string "oauth_uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["oauth_provider", "oauth_uid"], name: "index_users_on_oauth_provider_and_oauth_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_messages", "chat_sessions"
  add_foreign_key "chat_sessions", "materials"
  add_foreign_key "chat_sessions", "users"
  add_foreign_key "llm_events", "materials"
  add_foreign_key "llm_events", "users"
  add_foreign_key "material_chunks", "materials"
  add_foreign_key "materials", "users"
  add_foreign_key "notes", "materials"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quizzes", "materials"
end
