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

ActiveRecord::Schema.define(version: 20171013084601) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "anchors", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.float "total", null: false
    t.float "income", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "budget_records", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shop"
    t.integer "purse", default: 0
    t.integer "tag_id", default: 0
    t.boolean "is_conversion", default: false
    t.float "income_amount", default: 0.0, null: false
    t.float "expense_amount", default: 0.0, null: false
    t.integer "income_currency_id"
    t.integer "expense_currency_id"
  end

  create_table "currencies", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.boolean "is_stock", default: false
    t.boolean "update_regularly", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "round", default: 2
  end

  create_table "prices", id: :serial, force: :cascade do |t|
    t.date "actual_date"
    t.float "rate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "currency_id"
    t.date "date"
    t.integer "record_type", default: 0
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.text "title"
    t.integer "parent_id"
    t.string "image"
  end

end
