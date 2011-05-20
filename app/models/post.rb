class Post < ActiveRecord::Base
  belongs_to :blog

  # Associated Node attributes
  has_one :node, :as => :page, :dependent => :destroy
  accepts_nested_attributes_for :node

  #  validates_associated :node
  before_validation :update_node
  after_save  :update_cache_chain
  before_destroy :update_cache_chain
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching Post #{id} ********** "
    self.touch
    self.blog.try(:update_cache_chain)
  end




  ####################################################################
  # Helpers
  ###########

  # Updates this Object's Node, setting all the attributes correctly and creating the node if need be
  def update_node
    node = self.node ? self.node : self.build_node
    unless title.blank?
      node.title =  title
      node.menu_name = title
      node.set_safe_shortcut(title)
    end
    node.displayed = true
    node.parent = blog.node if blog and blog.node
  end

  def post_date
    temp = super
    temp.blank? ? created_at : temp
  end

end

