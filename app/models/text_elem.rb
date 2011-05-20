class TextElem < ActiveRecord::Base
  has_one :element, :as => :elem, :dependent => :destroy
  accepts_nested_attributes_for :element




  ####################################################################
  # Validations and Callbacks
  ###########
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching TextElem #{id} ********** "
    self.touch
    self.element.try(:update_cache_chain)
  end

end
