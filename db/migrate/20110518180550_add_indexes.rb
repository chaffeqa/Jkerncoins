class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :product_images, :item_id
    add_index :product_images, [:item_id, :primary_image]
    add_index :questions, :user_id

    add_index :nodes, :parent_id
    add_index :nodes, [:parent_id, :position, :displayed]
    add_index :nodes, :shortcut
    add_index :nodes, [:page_id, :page_type]
    
    add_index :elements, :dynamic_page_id
    add_index :elements, [:dynamic_page_id, :page_area, :position]
    add_index :elements, [:elem_id, :elem_type]

    add_index :link_elems, :node_id
    add_index :link_elems, :image_id    
    add_index :posts, :blog_id
    add_index :posts, [:blog_id, :post_date]
    add_index :events, :calendar_id
    add_index :events, [:start_at, :end_at]
    add_index :events, [:calendar_id, :start_at, :end_at]
    add_index :calendar_elems, :calendar_id
    add_index :item_elems, :item_id
    add_index :item_list_elems, :category_id
    
    add_index :blog_elem_links, :blog_id
    add_index :blog_elem_links, :blog_elem_id
    add_index :blog_elem_links, [:blog_id, :blog_elem_id]
  end

  def self.down
    remove_index :product_images, :item_id
    remove_index :product_images, [:item_id, :primary_image]
    remove_index :questions, :user_id
    
    remove_index :nodes, :parent_id
    remove_index :nodes, [:parent_id, :position, :displayed]
    remove_index :nodes, :shortcut
    remove_index :nodes, [:page_id, :page_type]
    
    remove_index :elements, :dynamic_page_id
    remove_index :elements, [:dynamic_page_id, :page_area, :position]
    remove_index :elements, [:elem_id, :elem_type]
    
    remove_index :link_elems, :node_id
    remove_index :link_elems, :image_id
    remove_index :posts, :blog_id
    remove_index :posts, [:blog_id, :post_date]
    remove_index :events, :calendar_id
    remove_index :events, [:start_at, :end_at]
    remove_index :events, [:calendar_id, :start_at, :end_at]
    remove_index :calendar_elems, :calendar_id
    remove_index :item_elems, :item_id
    remove_index :item_list_elems, :category_id
    
    remove_index :blog_elem_links, :blog_id
    remove_index :blog_elem_links, :blog_elem_id
    remove_index :blog_elem_links, [:blog_id, :blog_elem_id]
  end
end
