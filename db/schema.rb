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

ActiveRecord::Schema[7.2].define(version: 2024_12_12_073810) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.text "text", null: false
    t.boolean "public", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "plots", force: :cascade do |t|
    t.string "title", null: false
    t.geometry "polygon", limit: {:srid=>0, :type=>"st_polygon"}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.text "description"
    t.string "hero_image_url"
    t.integer "tile_population_status", default: 0
    t.index ["project_id"], name: "index_plots_on_project_id"
  end

  create_table "post_associations", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.string "postable_type"
    t.bigint "postable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "postable_type", "postable_id"], name: "index_post_associations_on_post_and_postable", unique: true
    t.index ["post_id"], name: "index_post_associations_on_post_id"
    t.index ["postable_type", "postable_id"], name: "index_post_associations_on_postable"
  end

  create_table "post_views", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shared_access_key"
    t.index ["post_id"], name: "index_post_views_on_post_id"
    t.index ["user_id"], name: "index_post_views_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preview"
    t.datetime "published_at", precision: nil
    t.index ["author_id"], name: "index_posts_on_author_id"
  end

  create_table "prices", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "amount_display"
    t.string "title"
    t.string "stripe_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_prices_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "hero_image_url"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "website"
    t.text "welcome_text"
    t.text "subscriber_benefits"
    t.boolean "public", default: true, null: false
  end

  create_table "promo_codes", force: :cascade do |t|
    t.string "code"
    t.string "stripe_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_promo_codes_on_code", unique: true
    t.index ["stripe_id"], name: "index_promo_codes_on_stripe_id", unique: true
  end

  create_table "redemption_invites", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.string "recipient_name"
    t.string "recipient_email"
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id"], name: "index_redemption_invites_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "subscriber_id"
    t.bigint "tile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_id", null: false
    t.integer "stripe_status"
    t.integer "price_pence"
    t.integer "recurring_interval"
    t.string "claim_email"
    t.string "claim_hash"
    t.bigint "redeemer_id"
    t.bigint "project_id"
    t.index ["project_id"], name: "index_subscriptions_on_project_id"
    t.index ["redeemer_id"], name: "index_subscriptions_on_redeemer_id"
    t.index ["stripe_id"], name: "index_subscriptions_on_stripe_id", unique: true
    t.index ["subscriber_id"], name: "index_subscriptions_on_subscriber_id"
    t.index ["tile_id"], name: "index_subscriptions_on_tile_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "logo_url"
    t.string "website"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "tiles", force: :cascade do |t|
    t.geometry "southwest", limit: {:srid=>0, :type=>"st_point"}, null: false
    t.geometry "northeast", limit: {:srid=>0, :type=>"st_point"}, null: false
    t.string "w3w", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "plot_id"
    t.bigint "latest_subscription_id"
    t.index ["latest_subscription_id"], name: "index_tiles_on_latest_subscription_id"
    t.index ["plot_id"], name: "index_tiles_on_plot_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "stripe_customer_id"
    t.bigint "team_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "plots", "projects"
  add_foreign_key "post_associations", "posts"
  add_foreign_key "post_views", "posts"
  add_foreign_key "post_views", "users"
  add_foreign_key "posts", "users", column: "author_id"
  add_foreign_key "prices", "projects"
  add_foreign_key "redemption_invites", "subscriptions"
  add_foreign_key "subscriptions", "projects"
  add_foreign_key "subscriptions", "tiles"
  add_foreign_key "subscriptions", "users", column: "redeemer_id"
  add_foreign_key "subscriptions", "users", column: "subscriber_id"
  add_foreign_key "tiles", "plots"
  add_foreign_key "tiles", "subscriptions", column: "latest_subscription_id"
  add_foreign_key "users", "teams"
end
