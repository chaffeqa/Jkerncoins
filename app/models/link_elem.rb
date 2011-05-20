class LinkElem < ActiveRecord::Base
  belongs_to :node
  belongs_to :image, :class_name => 'Ckeditor::Picture'
  belongs_to :link_list_elem

#  has_attached_file :link_file,
#    :url => '/site_assets/files/link_file_:id.:extension',
#    :path => ":rails_root/public/site_assets/files/link_file_:id.:extension"

  has_attached_file :link_file,
    :storage => :s3,
    :s3_credentials => S3_CREDENTIALS,
    :path => '/site_assets/files/link_file_:id.:extension'

  TARGET_OPTIONS = [ '', '_blank' ]
  LINK_TYPE_OPTIONS = [ 'Page', 'Url', 'File' ]

  validates_presence_of :link_name, :link_type
  validates :link_type, :inclusion => { :in => LINK_TYPE_OPTIONS }
  validates :target, :inclusion => { :in => TARGET_OPTIONS }, :allow_blank => true
  
  #Callbacks
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching LinkElem #{id} ********** "
    self.touch
    self.element.try(:update_cache_chain)
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

  def self.link_type_options
    LINK_TYPE_OPTIONS
  end
end
