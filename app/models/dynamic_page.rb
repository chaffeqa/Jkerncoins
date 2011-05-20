class DynamicPage < ActiveRecord::Base
#  belongs_to :node
  has_many :elements, :order => :position
  
  # Associated Node attributes
  has_one :node, :as => :page, :dependent => :destroy
  accepts_nested_attributes_for :node


  #Callbacks
  after_save :update_cache_chain
  before_destroy :update_cache_chain
  
  
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    unless self.marked_for_destruction?
      logger.debug "DB ********** Touching DynamicPage #{id} ********** "
      self.touch
    end
    if node
      logger.debug "DB ********** Touching Node #{node.title} ********** "
      self.node.touch
    end
  end

  VIEW_NAMES = [
    "Home",
    "Inside"
  ]

#  validates :template_name, :inclusion => { :in => VIEW_NAMES }


  def underscore_template_name
    template_name.gsub(/ /, '_').underscore
  end


end
