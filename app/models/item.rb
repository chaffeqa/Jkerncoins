class Item < ActiveRecord::Base
  ####################################################################
  # Associations
  ###########
  has_many :product_images, :limit => 10, :dependent => :destroy
  has_one :main_image, :class_name => "ProductImage", :conditions => {:primary_image => true}
  accepts_nested_attributes_for :product_images, :allow_destroy => true, :reject_if => proc { |attributes| attributes['image'].blank? and attributes['id'].blank? }
  has_many :item_elems

  # Associated Node attributes
  has_many :categories, :finder_sql =>
    'SELECT cats.* FROM categories AS cats
    JOIN nodes AS parent_n ON parent_n.page_id = cats.id AND parent_n.page_type = \'Category\'
    JOIN nodes AS item_n ON parent_n.id = item_n.parent_id
    WHERE item_n.page_id = #{id} AND item_n.page_type = \'Item\''
  has_many :nodes, :as => :page, :dependent => :destroy, :validate => true
  accepts_nested_attributes_for :nodes, :allow_destroy => true, :reject_if => proc { |attributes| attributes['parent_id'].blank? }



  ####################################################################
  # Validations and Callbacks
  ###########

  # Validations
  validates_presence_of :item_id, :cost, :name
  validates_numericality_of :cost

  # Callbacks
  before_validation :update_nodes
  after_save        :cat_update_item_count
  after_destroy     :full_item_counts_update
  after_save        :update_cache_chain
  before_destroy    :update_cache_chain
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  # Since autosave doesn't seem to be working, this will force the item_categories to resave
  def update_cache_chain
    logger.debug "DB ********** Touching Item #{id} ********** "
    self.touch
    self.item_elems.each {|elem| elem.try(:update_cache_chain) }
  end






  ####################################################################
  # Scopes
  ###########
  scope :get_for_sale, where(:for_sale => true)
  scope :displayed, where(:display => true)
  scope :scope_display, lambda {|display| where(:display => eval(display)) if ['true','false'].include?(display)}
  scope :scope_for_sale, lambda {|for_sale| where(:for_sale => for_sale)}
  scope :scope_name, lambda {|name| where('UPPER(name) LIKE UPPER(?)', '%'+name+'%')}
  scope :scope_details, lambda {|name| where('UPPER(details) LIKE UPPER(?)', "%"+name+"%")}
  scope :scope_meta, lambda {|meta| where('UPPER(meta) LIKE UPPER(?)', "%"+meta+"%")}
  scope :scope_item_id, lambda {|item_id| where('UPPER(item_id) LIKE UPPER(?)', "%"+item_id+"%")}
  scope :scope_category, lambda {|title| includes(:nodes => {:parent => :category}).where('UPPER(categories.title) LIKE UPPER(?)', "%"+title+"%")}
  scope :scope_text, lambda {|text| where('UPPER(name) LIKE UPPER(?) or UPPER(meta) LIKE UPPER(?) or UPPER(details) LIKE UPPER(?)', "%"+text+"%", "%"+text+"%", "%"+text+"%")}
  scope :scope_min_price, lambda {|price| where('cost >= ?', price)}
  scope :scope_max_price, lambda {|price| where('cost <= ?', price)}
  scope :in_category_array, lambda {|category_array| includes(:nodes).where('nodes.parent_id IN (?)', category_array )}


  ####################################################################
  # Helpers
  ###########

  # updates the attributes for each node for this item
  def update_nodes
    incr = 0
    self.nodes.build(:displayed => true) if not new_record? and self.nodes.count == 0  # Insure at least 1 node
    self.nodes.each do |node|
      node.title = name
      node.menu_name = name
      node.set_safe_shortcut("#{incr.to_s}-#{name}")
      node.displayed = display
      incr += 1
    end
  end


  def thumbnail_image
    self.main_image ? self.main_image.thumbnail_image : 'no_image_thumb.gif'
  end

  def original_image
    self.main_image ? self.main_image.full_size_image : 'no_image_full_size.gif'
  end

  def short_details
    return self.details[0,30] << "..."
  end





  private

  # performs a quick update on this item's category item_counts, as well as their ancestors
  def cat_update_item_count
    self.categories.each do |category|
      if (category.displayed_items.count - 1) == category.item_count
        category.inc_item_count
      end
      if (category.displayed_items.count + 1) == category.item_count
        category.dec_item_count
      end
    end
  end

  def full_item_counts_update
    Category.full_item_counts_update
  end


end

