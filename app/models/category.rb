class Category < ActiveRecord::Base

  ####################################################################
  # Associations
  ###########
  has_many :items, :class_name => 'Item', :finder_sql =>
    'SELECT item.* FROM items AS item
    JOIN nodes AS item_node ON item_node.page_id = item.id AND item_node.page_type = \'Item\'
    JOIN nodes AS cat_node ON item_node.parent_id = cat_node.id
    WHERE cat_node.page_id = #{id} AND cat_node.page_type = \'Category\''


  has_many :displayed_items, :class_name => 'Item', :finder_sql =>
    'SELECT item.* FROM items AS item
    JOIN nodes AS item_node ON item_node.page_id = item.id AND item_node.page_type = \'Item\'
    JOIN nodes AS cat_node ON item_node.parent_id = cat_node.id
    WHERE cat_node.page_id = #{id} AND cat_node.page_type = \'Category\'
    AND item.display = 1'


  # Associated Node attributes
  has_one :node, :as => :page, :dependent => :destroy
  accepts_nested_attributes_for :node

#  has_attached_file :image,
#    :url  => "/site_assets/categories/:id/image_:style.:extension",
#    :path => ":rails_root/public/site_assets/categories/:id/image_:style.:extension",
#    :styles => { :thumb => ['112x112#', :png] }
    
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => S3_CREDENTIALS,
    :path => "/site_assets/categories/:id/image_:style.:extension",
    :styles => { :thumb => ['112x112#', :png] }




  ####################################################################
  # Validations and Callbacks
  ###########
  
  validates :title, :presence => true, :uniqueness => true
  
  before_validation :update_node
  after_save  :update_cache_chain
  before_destroy :update_cache_chain
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching Category #{title} ********** "
    self.touch
  end



  ####################################################################
  # Helpers
  ###########


  def update_node
    node = self.node ? self.node : self.build_node
    unless self.title.blank?
      node.title =  title
      node.menu_name = title
    end
    node.displayed = true
    node.parent ||= Node.inventory_node
  end

  # Decrements the item count and asks parent to do the same
  def dec_item_count
    self.item_count -= 1
    self.save!
    if node.parent && node.parent.page_type == "Category"
      node.parent.category.dec_item_count
    end
  end

  # Increments the item count and asks parent to do the same
  def inc_item_count
    self.item_count += 1
    self.save!
    if node.parent && node.parent.page_type == "Category"
      node.parent.category.inc_item_count
    end
  end

  # Sets the item_count of this category to the correct value.
  #   Returns true if the item_count value did not change, False otherwise.
  def set_item_count
    temp_item_count = 0
    prev_count = item_count
    temp_item_count += displayed_items.count
    node.children.categories.each {|node| temp_item_count += node.category.item_count}
    self.item_count = temp_item_count
    return (prev_count == temp_item_count)
  end


  ####################################################################
  # Scopes
  ###########

  scope :title_like, lambda {|title| where('title LIKE ?', title)}
  scope :has_subcategories, joins(:node => :children).where('children_nodes.page_type = ?', 'Category')

  # Returns true if this category has an item
  def has_items?
    return false if self.node.children.empty?
    child = self.node.children.first
    if child.page_type == 'Item'
      return true
    end
    return false
  end

  # Returns the root category
  def self.get_inventory
    self.where(:title => 'Inventory').first
  end

  # Returns all leaf categories
  def self.leaf_categories
    self.all - self.has_subcategories
  end


  ####################################################################
  # Helpers
  ###########

  def thumbnail_image
    self.image? ? self.image.url(:thumb) : 'no_image_thumb.gif'
  end
  def original_image
    self.image? ? self.image.url : 'no_image_full_size.gif'
  end

  # Returns an array of all the node ID's of this categories' decendents plus this category
  def search_categories_array
    return get_child_category_node_ids(self.node)
  end

  # Recursively returns this node and all the decendent node ID's of the passed in node
  def get_child_category_node_ids(node)
    children = node.children.categories
    array = [node.id] # children.collect {|child| child.id }
    children.each do |child|
      array += get_child_category_node_ids(child)
    end
    return array
  end




  #############################
  # Recursively set item counts
  #############################

  # Recursive setter of this category's item_count
  def set_item_counts
    children_item_count = 0
    node.children.categories.each  {|child_node| children_item_count += child_node.category.set_item_counts }
#    puts "#{title} category: items: #{displayed_items.count}, child_categories' items: #{children_item_count}"
    self.item_count = (displayed_items.count + children_item_count)
    self.save!
    return self.item_count
  end

  # Performs recursive setting of all the categories' item_counts
  def self.full_item_counts_update
    inventory_category = Category.get_inventory
    inventory_category.set_item_counts
  end

  #############################
  #############################

end

