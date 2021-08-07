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

ActiveRecord::Schema.define(version: 2021_08_07_142906) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "plpgsql"

  create_table "budget_records", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shop"
    t.integer "tag_id", default: 0
    t.boolean "is_conversion", default: false
    t.bigint "income_amount", default: 0, null: false
    t.bigint "expense_amount", default: 0, null: false
    t.integer "income_currency_id"
    t.integer "expense_currency_id"
    t.boolean "is_credit", default: false
  end

  create_table "currencies", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.boolean "update_regularly", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "round", default: 2
    t.string "record_type"
    t.jsonb "api"
  end

  create_table "monthly_diffs", force: :cascade do |t|
    t.date "date"
    t.bigint "amount", default: 0
    t.bigint "currency_id"
    t.datetime "updated_at"
    t.index ["currency_id"], name: "index_monthly_diffs_on_currency_id"
  end

  create_table "prices", id: :serial, force: :cascade do |t|
    t.date "actual_date"
    t.float "rate"
    t.datetime "created_at"
    t.integer "currency_id"
    t.index ["actual_date"], name: "index_prices_on_actual_date", using: :gist
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.text "title"
    t.integer "parent_id"
    t.string "image"
    t.string "color"
  end

end
