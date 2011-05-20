class ItemElem < ActiveRecord::Base
  belongs_to :item
  has_one :element, :as => :elem, :dependent => :destroy
  accepts_nested_attributes_for :element

  DISPLAY_TYPE = [
    "Thumbnail",
    "Full Display",
    "Limited Display"
  ]



#  validates_numericality_of :limit
  validates_presence_of :item_id
  validates_associated :item
  validates :display_type, :inclusion => { :in => DISPLAY_TYPE }
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching ItemElem #{id} ********** "
    self.touch
    self.element.try(:update_cache_chain)
  end

  def self.display_type_select
    DISPLAY_TYPE
  end

  def display_type_partial
    self.display_type.downcase.gsub(" ", "_")
  end
end
