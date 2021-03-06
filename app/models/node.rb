class Node < ActiveRecord::Base
  ####################################################################
  # Associations
  ###########
  belongs_to :page, :polymorphic => true
  belongs_to :category, :class_name => 'Category', :foreign_key => "page_id"
  belongs_to :item, :class_name => 'Item', :foreign_key => "page_id"
  has_many   :link_elems

  acts_as_tree :order => 'position'
  acts_as_list :scope => :parent_id


  ####################################################################
  # Validations and Callbacks
  ###########

  #Validations
  validate :basic_validations
  validate :check_unique_shortcut?
  #  validate :ensure_unique_root_node

  #Callbacks
  # NOTE: dont need if basic_validations works!
#  before_validation :fill_missing_fields
  after_save :update_cache_chain
  before_destroy :update_cache_chain

  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache
  # Clears the cache items of Node calls
  def update_cache_chain
    unless self.marked_for_destruction?
      logger.debug "DB ********** Touching Node #{title} ********** "
      self.touch
    end
    if parent
      logger.debug "DB ********** Touching Node #{parent.title} ********** "
      self.parent.update_cache_chain
    end
    self.link_elems.each {|elem| elem.try(:update_cache_chain) }
  end

  # Ensures the fields for this node are all filled, and if not, attempts to fill them
  def fill_missing_fields
    unless self.title.blank?
      self.menu_name = self.title if self.menu_name.blank?
      self.shortcut = self.title.parameterize.html_safe if self.shortcut.blank?
    else
      unless self.menu_name.blank?
        self.title = self.menu_name if self.title.blank?
        self.shortcut = self.menu_name.parameterize.html_safe if self.shortcut.blank?
      end
    end
  end

  def ensure_unique_root_node
    root_nodes = Node.where(:parent_id => nil)
    if root_nodes.count > 1
      problem_nodes = root_nodes - (Node.where(:parent_id => nil).where(:title => 'Home') )
      problem_nodes.each {|node| node.update_attributes(:displayed => false, :parent_id => ' ') }
    end
    true
  end

  # Checks the database to ensure the Shortcut is not already taken
  def check_unique_shortcut?
    if (not new_record? and Node.where('nodes.shortcut = ? AND nodes.id != ?', shortcut, id).exists?) or (new_record? and Node.exists?(:shortcut => shortcut))
      puts "Problem Node: (Title: #{title}, ID: #{id} URL: #{shortcut}), new_record: #{new_record?}"
      addition = Node.where('shortcut LIKE ?', shortcut).count
      suggested = self.shortcut + "_" + addition.to_s
      errors.add(:shortcut, "URL shortcut already exists in this site.  Suggested Shortcut: '#{suggested}'")
    end
  end

  # Checks the shortcut to ensure the string is HTML safe.
  def basic_validations
    if title.blank?
      errors.add(:title, 'Title cannot be blank.')
    else
      self.menu_name = self.title if menu_name.blank?
      self.shortcut = self.title.parameterize.html_safe if shortcut.blank?
      errors.add(:shortcut, "Shortcut cannot contain spaces") if shortcut.include? " "
      errors.add(:shortcut, "Shortcut cannot contain slashes") if shortcut.include? "/"
      errors.add(:shortcut, "Shortcut cannot contain '?'") if shortcut.include? "?"
    end
  end


  ####################################################################
  # Scopes
  ###########

  scope :displayed, where(:displayed => true)
  scope :dynamic_pages, where(:page_type => 'DynamicPage')
  scope :categories, where(:page_type => 'Category')
  scope :calendars, where(:page_type => 'Calendar')
  scope :items, where(:page_type => 'Item')
  scope :no_items, where("page_type != 'Item' OR page_type IS NULL")

  def self.home
    where(:shortcut => 'Home').first
  end

  def self.find_shortcut(shortcut='')
    where(:shortcut => shortcut).first unless shortcut.blank?
  end


  ####################################################################
  # Helpers
  ###########

  # Returns the URL of this node.
  def url
    if self.controller and self.action and self.page_id
      return "/#{self.controller}/#{self.action}/#{self.page_id}"
    end
    if self.controller and self.action
      return "/#{self.controller}/#{self.action}"
    end
    if self.controller
      return "/#{self.controller}"
    end
    return "/#{self.shortcut}"
  end

  # Returns the Blog node
  def self.blog_node
    self.where(:title => 'Blogs').first
  end

  # Returns the Calendar Node
  def self.calendar_node
    self.where(:title => 'Calendars').first
  end

  # Returns the Inventory Node
  def self.inventory_node
    self.where(:title => 'Inventory').first
  end
  
  def set_category_item_count
    new_item_count = category.displayed_items.count + children.categories.collect {|node| node.set_category_item_count }.reduce(:+).to_i
    category.update_column(:item_count, new_item_count) if new_item_count != category.item_count
    new_item_count
  end

  # Sets this node's shortcut to the desired shortcut or closest related shortcut that will be unique in the database.  If a conflict
  # occurs than a numeric increment will be appended as a prefix and the increment number will be returned.  If no conflict occured
  # than the method will return 0 (or the passed in increment if one was passed in)
  def set_safe_shortcut(shtcut=nil)
    shtcut ||= self.shortcut || ''
    node_id = self.id || 0
    desired_shortcut = parameterize(shtcut.clone) # Clone since trouble with copying
    prefix = ""; incr = 0
    while Node.where('nodes.shortcut = ? AND nodes.id != ?', prefix + desired_shortcut, node_id).exists?
      incr += 1
      prefix = incr.to_s + "-"
    end
    self.shortcut = prefix + desired_shortcut
  end

  # Called to order the Node tree based on passed in json
  def self.order_tree(json)
    Node.update_all(['position = ?', nil])
    Node.order_helper(json)
  end


  def valid_url?
    true
  end



  ####################################################################
  # Node Tree Creator
  ##########

  # Caller for the FLAT (level 1 and 2 combined) node tree creation
  def flat_node_tree
    flat_tree = ([{
        :key => "node_#{id}".to_sym,
        :name => menu_name,
        :url => url,
        :options => {:class => "#{page_type} #{displayed ? '' : 'not-displayed'}"},
        :items => []
    }] + children.displayed.collect {|node| node.tree_hash_value } )
    flat_tree
  end

  # Caller for the node tree creation
  def node_tree
    tree = [tree_hash_value]
    tree
  end

  # Basic node hash for the node tree
  def tree_hash_value
    {
      :key => "node_#{self.id}".to_sym,
      :name => self.menu_name,
      :url => self.url,
      :options => {:class => "#{self.page_type} #{self.displayed ? '' : 'not-displayed'}"},
      :items => children.displayed.collect {|node| node.tree_hash_value }
    }
  end



  ####################################################################
  # HTML renderer
  ###########

  # Creates a string of the html for a breadcrumb for this node
  def html_breadcrumb
    (cached(:ancestors).reverse.map {|node| node.html_link } << html_link).join(" &gt; ").html_safe
  end

  # Creates a string of the html link for this node
  def html_link(selected=false)
    "<a#{selected ? ' class="selected"' : ''} href='#{url}'>#{menu_name}</a>"
  end

  # Creates a string of the html of this node's full tree (up to the root)
  def html_ul_tree
    Node.home.children_ul_row(cached(:ancestor_ids), cached(:ancestor_ids) + [id]).html_safe
  end

  # Creates a string of the html of this node's <li> element
  def li_row(expanded_node_ids, selected_node_ids)
    selected = selected_node_ids.include?(id)
    expand = selected and not (cached_displayed_children.nil? or cached_displayed_children.empty?)
    li_string = "<li id='#{shortcut}' class='#{page_type.to_s + (selected ? ' selected' : '')}'>"
    li_string += html_link(selected)
    li_string += children_ul_row(expanded_node_ids, selected_node_ids) if expand
    li_string += "</li>"
    li_string
  end

  # Creates a string of the html of this node's children inside a <ul>
  def children_ul_row(expanded_node_ids, selected_node_ids)
    row_string = "<ul>"
    cached_displayed_children.each do |node|
      row_string += node.li_row(expanded_node_ids, selected_node_ids)
    end
    row_string += "</ul>"
    row_string
  end







  ####################################################################
  # Cached Calls
  ###########

  # A sick move, basically it caches any chaining of methods (for triggering if a view calls it)
  def view_cached(*methods)
   return result = self.send(*methods) unless VIEW_FRAGMENT_CACHING
   logger.debug "\n******************\n [Cache] Retreiving node(#{self.id})'s view_cached_#{methods.inspect} \n******************\n\n"
   Rails.cache.fetch(self.cache_key + "::#{methods.join('.')}", :expires_in => 20.days) {
     logger.debug "\n******************\n [Cache] (MISSED) Caching node(#{self.id})'s view_cached_#{methods.inspect} \n******************\n\n"
     result = self.send(*methods) # Using result to make sure the method marshels, and memcache doesnt save a SQL query string
   }
  end

  # A sick move, basically it caches any chaining of methods
  def cached(*methods)
   return result = self.send(*methods) unless MODEL_CACHING
   logger.debug "\n******************\n [Cache] Retreiving node(#{self.id})'s cached_#{methods.inspect} \n******************\n\n"
   Rails.cache.fetch(self.cache_key + "::#{methods.join('.')}", :expires_in => 20.days) {
     logger.debug "\n******************\n [Cache] (MISSED) Caching node(#{self.id})'s cached_#{methods.inspect} \n******************\n\n"
     result = self.send(*methods) # Using result to make sure the method marshels, and memcache doesnt save a SQL query string
   }
  end

  # Returns a cached array of this node's displayed children
  def cached_displayed_children
   return self.children.displayed unless MODEL_CACHING
   logger.debug "\n******************\n [Cache] Retreiving node(#{self.id})'s cached_displayed_children \n******************\n\n"
    Rails.cache.fetch(self.cache_key + "::displayed_children", :expires_in => 20.days) {
      logger.debug "\n******************\n [Cache] (MISSED) Caching node(#{self.id})'s cached_displayed_children \n******************\n\n"
      self.children.displayed.collect {|n| n }
    }
  end

  # Returns a cached array of this node's displayed category children
  def cached_displayed_item_children
   return self.children.displayed.items unless MODEL_CACHING
   logger.debug "\n******************\n [Cache] Retreiving node(#{self.id})'s cached_displayed_item_children \n******************\n\n"
    Rails.cache.fetch(self.cache_key + "::displayed_item_children", :expires_in => 20.days) {
      logger.debug "\n******************\n [Cache] (MISSED) Caching node(#{self.id})'s cached_displayed_item_children \n******************\n\n"
      self.children.displayed.items.collect {|n| n }
    }
  end

  # Returns a cached array of this node's displayed item children
  def cached_displayed_category_children
   return self.children.displayed.categories unless MODEL_CACHING
   logger.debug "\n******************\n [Cache] Retreiving node(#{self.id})'s cached_displayed_category_children \n******************\n\n"
   Rails.cache.fetch(self.cache_key + "::displayed_category_children", :expires_in => 20.days) {
      logger.debug "\n******************\n [Cache] (MISSED) Caching node(#{self.id})'s cached_displayed_category_children \n******************\n\n"
      self.children.displayed.categories.collect {|n| n }
    }
  end






  ####################################################################
  # Ancestors
  ###########

   # Caches and returns this nodes ancestor objects
   def ancestors
     (parent.nil? ? [] : [parent] + parent.cached(:ancestors))
   end

   # Caches and returns this nodes ancestor ids
   def ancestor_ids
    cached(:ancestors).collect(&:id)
   end




  private

  # Actual behind the scenes ordering of the Node tree
  def self.order_helper( json, position = 0, parent_id = nil)
    json.each do |hash|
      node_id = hash['attr']['id'].delete('node_')
      Node.update_all(['position = ?, parent_id = ?', position, parent_id], ['id = ?', node_id])
      position += 1
      if hash['children']
        order_helper( hash['children'], 0, node_id)
      end
    end
  end

  # Replaces special characters in a string so that it may be used as part of a ‘pretty’ URL.
  def parameterize(parameterized_string, sep = '-')
    # Turn unwanted chars into the separator
    parameterized_string.gsub!(/[^a-zA-Z0-9\-_]+/, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
    end
    parameterized_string.downcase
  end


  # Node error logger TODO
  def log_problem_node(msg)
    logger.error "DB ********** Node Error **********"
    logger.error "Node (id: #{self.id || ''}, title: #{self.title || ''})"
    logger.error "Error: '#{msg}'"
    logger.error "DB ******** End Node Error ********"
  end






  # Called to order the Node tree based on passed in json
  def self.order_tree(json)
#    self.update_all(['position = ?', nil])
    errors = self.order_helper(json)
    return errors
  end

end

