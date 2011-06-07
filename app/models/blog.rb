class Blog < ActiveRecord::Base

  ####################################################################
  # Associations
  ###########
  has_many :posts
  belongs_to :blog_elem
  has_many :blog_elem_links, :dependent => :destroy
  has_many :blog_elems, :through => :blog_elem_links


  ####################################################################
  # Validations and Callbacks
  ###########

  # Associated Node attributes
  has_one :node, :as => :page, :dependent => :destroy, :validate => true
  accepts_nested_attributes_for :node
  before_save :update_node
  after_save :update_cache_chain
  before_destroy :update_cache_chain
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching BlogElem #{id} ********** "
    self.touch
    self.blog_elems.each {|elem| elem.try(:update_cache_chain) }
    self.blog_elem.try(:update_cache_chain)
  end





  ####################################################################
  # Helpers
  ###########
  
  

  # Updates this Object's Node, setting all the attributes correctly and creating the node if need be
  def update_node
    self.title = unique_title if self.title.blank?
    node = self.node ? self.node : self.build_node
    node.title =  title
    node.menu_name = title
    node.set_safe_shortcut(title)
    node.displayed = true
    node.parent ||= Node.blog_node
  end

  private

  def unique_title(i="")
    potential_title = "Blog#{i.to_s}"
    if Blog.where(:title => potential_title).exists?
      i = (i == "" ? 1 : i + 1 )
      return unique_title(i)
    else
      return potential_title
    end
  end



end

