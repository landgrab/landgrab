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

ActiveRecord::Schema[8.1].define(version: 2026_01_19_071930) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "postgis"

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

  create_table "comments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.boolean "public", default: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "plots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "hero_image_url"
    t.geometry "polygon", limit: {srid: 0, type: "st_polygon"}, null: false
    t.bigint "project_id"
    t.integer "tile_population_status", default: 0
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_plots_on_project_id"
  end

  create_table "post_associations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.bigint "postable_id"
    t.string "postable_type"
    t.datetime "updated_at", null: false
    t.index ["post_id", "postable_type", "postable_id"], name: "index_post_associations_on_post_and_postable", unique: true
    t.index ["post_id"], name: "index_post_associations_on_post_id"
    t.index ["postable_type", "postable_id"], name: "index_post_associations_on_postable"
  end

  create_table "post_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.string "shared_access_key"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_post_views_on_post_id"
    t.index ["user_id"], name: "index_post_views_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "author_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.text "preview"
    t.datetime "published_at", precision: nil
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_posts_on_author_id"
  end

  create_table "prices", force: :cascade do |t|
    t.string "amount_display"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "project_id", null: false
    t.string "stripe_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_prices_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "hero_image_url"
    t.string "logo_url"
    t.boolean "public", default: true, null: false
    t.text "subscriber_benefits"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "website"
    t.text "welcome_text"
  end

  create_table "promo_codes", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "stripe_id"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_promo_codes_on_code", unique: true
    t.index ["stripe_id"], name: "index_promo_codes_on_stripe_id", unique: true
  end

  create_table "redemption_invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "recipient_email"
    t.string "recipient_name"
    t.bigint "subscription_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_redemption_invites_on_subscription_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "claim_email"
    t.string "claim_hash"
    t.datetime "created_at", null: false
    t.integer "price_pence"
    t.bigint "project_id", null: false
    t.integer "recurring_interval"
    t.bigint "redeemer_id"
    t.string "stripe_id", null: false
    t.integer "stripe_status"
    t.bigint "subscriber_id"
    t.bigint "tile_id"
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_subscriptions_on_project_id"
    t.index ["redeemer_id"], name: "index_subscriptions_on_redeemer_id"
    t.index ["stripe_id"], name: "index_subscriptions_on_stripe_id", unique: true
    t.index ["subscriber_id"], name: "index_subscriptions_on_subscriber_id"
    t.index ["tile_id"], name: "index_subscriptions_on_tile_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "logo_url"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "tiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "latest_subscription_id"
    t.geometry "northeast", limit: {srid: 0, type: "st_point"}, null: false
    t.bigint "plot_id"
    t.geometry "southwest", limit: {srid: 0, type: "st_point"}, null: false
    t.datetime "updated_at", null: false
    t.string "w3w", null: false
    t.index ["latest_subscription_id"], name: "index_tiles_on_latest_subscription_id"
    t.index ["plot_id"], name: "index_tiles_on_plot_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "stripe_customer_id"
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "plots", "projects"
  add_foreign_key "post_associations", "posts"
  add_foreign_key "post_views", "posts"
  add_foreign_key "post_views", "users"
  add_foreign_key "posts", "users", column: "author_id"
  add_foreign_key "prices", "projects"
  add_foreign_key "redemption_invites", "subscriptions"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "subscriptions", "projects"
  add_foreign_key "subscriptions", "tiles"
  add_foreign_key "subscriptions", "users", column: "redeemer_id"
  add_foreign_key "subscriptions", "users", column: "subscriber_id"
  add_foreign_key "tiles", "plots"
  add_foreign_key "tiles", "subscriptions", column: "latest_subscription_id"
  add_foreign_key "users", "teams"
end
