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

ActiveRecord::Schema.define(:version => 20110607010742) do

  create_table "admins", :force => true do |t|
    t.string   "email",                             :null => false
    t.string   "encrypted_password", :limit => 128, :null => false
    t.string   "password_salt",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], :name => "index_admins_on_email", :unique => true

  create_table "blog_elem_links", :force => true do |t|
    t.integer "blog_id"
    t.integer "blog_elem_id"
  end

  add_index "blog_elem_links", ["blog_elem_id"], :name => "index_blog_elem_links_on_blog_elem_id"
  add_index "blog_elem_links", ["blog_id", "blog_elem_id"], :name => "index_blog_elem_links_on_blog_id_and_blog_elem_id"
  add_index "blog_elem_links", ["blog_id"], :name => "index_blog_elem_links_on_blog_id"

  create_table "blog_elems", :force => true do |t|
    t.integer  "count_limit"
    t.string   "display_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "past_days_limit"
  end

  create_table "blogs", :force => true do |t|
    t.string   "title"
    t.text     "banner"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "blog_elem_id"
  end

  create_table "calendar_elems", :force => true do |t|
    t.string   "display_style"
    t.integer  "max_events_shown"
    t.integer  "max_days_in_past"
    t.integer  "max_days_in_future"
    t.integer  "calendar_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "calendar_elems", ["calendar_id"], :name => "index_calendar_elems_on_calendar_id"

  create_table "calendars", :force => true do |t|
    t.string   "title"
    t.text     "banner"
    t.string   "event_color"
    t.string   "background_color"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "item_count",         :default => 0
  end

  create_table "ckeditor_assets", :force => true do |t|
    t.string   "data_file_name",                                 :null => false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    :limit => 30
    t.string   "type",              :limit => 25
    t.string   "guid",              :limit => 10
    t.integer  "locale",                          :default => 0
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], :name => "fk_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], :name => "idx_assetable_type"
  add_index "ckeditor_assets", ["user_id"], :name => "fk_user"

  create_table "dynamic_pages", :force => true do |t|
    t.string   "template_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "elements", :force => true do |t|
    t.integer  "dynamic_page_id"
    t.integer  "position"
    t.integer  "elem_id"
    t.string   "elem_type"
    t.integer  "page_area"
    t.string   "title"
    t.boolean  "display_title",   :default => true
    t.string   "html_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "elements", ["dynamic_page_id", "page_area", "position"], :name => "index_elements_on_dynamic_page_id_and_page_area_and_position"
  add_index "elements", ["dynamic_page_id"], :name => "index_elements_on_dynamic_page_id"
  add_index "elements", ["elem_id", "elem_type"], :name => "index_elements_on_elem_id_and_elem_type"

  create_table "events", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean  "all_day",     :default => false
    t.string   "color"
    t.integer  "calendar_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["calendar_id", "start_at", "end_at"], :name => "index_events_on_calendar_id_and_start_at_and_end_at"
  add_index "events", ["calendar_id"], :name => "index_events_on_calendar_id"
  add_index "events", ["start_at", "end_at"], :name => "index_events_on_start_at_and_end_at"

  create_table "item_elems", :force => true do |t|
    t.integer  "item_id"
    t.string   "display_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_elems", ["item_id"], :name => "index_item_elems_on_item_id"

  create_table "item_list_elems", :force => true do |t|
    t.integer  "category_id"
    t.integer  "limit"
    t.decimal  "min_price",    :precision => 8, :scale => 2, :default => 0.0
    t.decimal  "max_price",    :precision => 8, :scale => 2, :default => 0.0
    t.string   "display_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "item_list_elems", ["category_id"], :name => "index_item_list_elems_on_category_id"

  create_table "items", :force => true do |t|
    t.string   "name"
    t.decimal  "cost",       :precision => 8, :scale => 2, :default => 0.0
    t.text     "details"
    t.string   "item_id"
    t.boolean  "for_sale"
    t.boolean  "display"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "meta"
  end

  create_table "link_elems", :force => true do |t|
    t.string   "link_name"
    t.string   "link_type"
    t.string   "link_url"
    t.integer  "node_id"
    t.string   "target"
    t.integer  "image_id"
    t.string   "img_src"
    t.boolean  "is_image"
    t.string   "image_style"
    t.string   "link_file_file_name"
    t.string   "link_file_content_type"
    t.integer  "link_file_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "link_list_elem_id"
  end

  add_index "link_elems", ["image_id"], :name => "index_link_elems_on_image_id"
  add_index "link_elems", ["node_id"], :name => "index_link_elems_on_node_id"

  create_table "link_list_elems", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "nodes", :force => true do |t|
    t.string   "title"
    t.string   "menu_name"
    t.string   "shortcut"
    t.integer  "parent_id"
    t.boolean  "displayed"
    t.integer  "page_id"
    t.string   "page_type"
    t.string   "controller"
    t.string   "action"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nodes", ["page_id", "page_type"], :name => "index_nodes_on_page_id_and_page_type"
  add_index "nodes", ["parent_id", "position", "displayed"], :name => "index_nodes_on_parent_id_and_position_and_displayed"
  add_index "nodes", ["parent_id"], :name => "index_nodes_on_parent_id"
  add_index "nodes", ["shortcut"], :name => "index_nodes_on_shortcut"

  create_table "posts", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "blog_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "post_date"
  end

  add_index "posts", ["blog_id", "post_date"], :name => "index_posts_on_blog_id_and_post_date"
  add_index "posts", ["blog_id"], :name => "index_posts_on_blog_id"

  create_table "product_images", :force => true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "item_id"
    t.boolean  "primary_image",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_images", ["item_id", "primary_image"], :name => "index_product_images_on_item_id_and_primary_image"
  add_index "product_images", ["item_id"], :name => "index_product_images_on_item_id"

  create_table "questions", :force => true do |t|
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company"
    t.string   "street_address_1"
    t.string   "street_address_2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "zip_code"
    t.string   "phone"
    t.string   "fax"
    t.string   "email"
    t.string   "website"
    t.string   "subject"
    t.text     "body"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions", ["user_id"], :name => "index_questions_on_user_id"

  create_table "text_elems", :force => true do |t|
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
