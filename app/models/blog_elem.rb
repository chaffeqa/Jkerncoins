class BlogElem < ActiveRecord::Base
  has_one :element, :as => :elem, :dependent => :destroy, :validate => true
  has_many :blog_elem_links, :dependent => :destroy
  has_many :blogs, :through => :blog_elem_links
  has_one :blog, :dependent => :destroy, :validate => true
  accepts_nested_attributes_for :element
  accepts_nested_attributes_for :blog

  DISPLAY_TYPE = [
    "Archive",
    "List",
    "List with Body"
  ]



  #  validates_numericality_of :limit
  validates :display_type, :inclusion => { :in => DISPLAY_TYPE }
  validates :past_days_limit, :numericality => {:allow_blank => true}
  validates :count_limit, :numericality => {:allow_blank => true}
  after_save :persist_title
  #  validates_associated :blog
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching BlogElem #{id} ********** "
    self.touch
    self.element.try(:update_cache_chain)
  end
  
  
  # Returns the posts that this blog_elem should display
  def get_posts
    posts = Post.order("post_date DESC").where('post_date <= ?', Time.now)
    posts = posts.limit(count_limit) unless count_limit.blank?
    posts = posts.where("posts.post_date >= ?", Time.now - past_days_limit.days) unless past_days_limit.blank?
    posts = posts.where("posts.blog_id IN (?)", [blog.id] + blog_ids )
  end


  def persist_title
    puts self.blog.title
    if self.element
      self.element.title = self.blog.title
      self.element.save
    end
  end

  def self.display_type_select
    DISPLAY_TYPE
  end

  def display_type_partial
    self.display_type.downcase.gsub(" ", "_")
  end
end

