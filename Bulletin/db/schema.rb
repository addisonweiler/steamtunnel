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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120212234516) do

  create_table "events", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "start"
    t.datetime "finish"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location"
    t.integer  "group_id"
    t.integer  "fb_id",       :limit => 8
    t.string   "permalink"
  end

  create_table "experiments", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favorites_users", :id => false, :force => true do |t|
    t.integer "event_id"
    t.integer "user_id"
  end

  add_index "favorites_users", ["event_id"], :name => "index_favorites_users_on_event_id"
  add_index "favorites_users", ["user_id"], :name => "index_favorites_users_on_user_id"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "facebook",    :default => false
    t.string   "source"
    t.string   "homepage"
    t.boolean  "personal",    :default => false
    t.text     "data"
    t.string   "thumbnail"
  end

  create_table "groups_tags", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "tag_id"
  end

  add_index "groups_tags", ["group_id"], :name => "index_groups_tags_on_group_id"
  add_index "groups_tags", ["tag_id"], :name => "index_groups_tags_on_tag_id"

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  add_index "groups_users", ["group_id"], :name => "index_groups_users_on_group_id"
  add_index "groups_users", ["user_id"], :name => "index_groups_users_on_user_id"

  create_table "memberships", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "selections_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  add_index "selections_users", ["group_id"], :name => "index_selections_users_on_group_id"
  add_index "selections_users", ["user_id"], :name => "index_selections_users_on_user_id"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",    :default => true
  end

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",                  :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",                     :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fb_token"
    t.integer  "fb_id",                  :limit => 8
    t.string   "name"
    t.text     "friends"
  end

end
