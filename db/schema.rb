# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160201205014) do

  create_table "account_charges", force: :cascade do |t|
    t.datetime "date"
    t.text     "target_cur"
    t.text     "charge_cur"
    t.float    "charge_amount"
    t.text     "notes"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "budget_daily_quota", force: :cascade do |t|
    t.date     "date",                     null: false
    t.float    "amount",     default: 0.0, null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "budget_expenses", force: :cascade do |t|
    t.date     "date",                      null: false
    t.float    "amount",      default: 0.0, null: false
    t.string   "description"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "budget_incomes", force: :cascade do |t|
    t.date     "date",                      null: false
    t.float    "amount",      default: 0.0, null: false
    t.string   "description"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "budget_required_expenses", force: :cascade do |t|
    t.date     "date",                      null: false
    t.float    "amount",      default: 0.0, null: false
    t.string   "description"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "budget_savings", force: :cascade do |t|
    t.date     "date",                      null: false
    t.float    "amount",      default: 0.0, null: false
    t.string   "description"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "currencies", force: :cascade do |t|
    t.date     "date"
    t.text     "currency"
    t.float    "rate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exchanges", force: :cascade do |t|
    t.datetime "date"
    t.text     "sold_cur"
    t.float    "sold_amount"
    t.text     "bought_cur"
    t.float    "bought_amount"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_income",     default: true
  end

  create_table "expenses", force: :cascade do |t|
    t.datetime "date"
    t.text     "cur"
    t.float    "amount"
    t.text     "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profits", force: :cascade do |t|
    t.datetime "date"
    t.text     "cur"
    t.float    "amount"
    t.text     "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
