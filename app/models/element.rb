#require  ActiveSupport::CoreExtensions::String
class Element < ActiveRecord::Base
  belongs_to :dynamic_page
  belongs_to :elem, :polymorphic => true

  acts_as_list :scope => 'dynamic_page_id = #{dynamic_page_id} AND page_area = #{page_area}'
  #acts_as_list :scope => :dynamic_page_id NOTE old SliceHost

  ELEM_TYPES = [
    ["Text"             ,   "text_elems"            ],
    ["Link List"        ,   "link_list_elems"       ],
    ["Item"             ,   "item_elems"            ],
    ["Item List"        ,   "item_list_elems"       ],
    #    ["Inventory Search" ,   "inventory_search_elems"],
    #    ["Recent News"      ,   "recent_news_elems"     ],
    ["Login"            ,   "login_elems"           ],
    ["Blog"             ,   "blog_elems"            ],
    ["Calendar"         ,   "calendar_elems"        ],
    #    ["Photo Gallery"    ,   "photo_gallery_elems"   ]
  ]


#  validates_numericality_of :position
  validates :page_area, :numericality => true
  
  #Callbacks
  before_save :create_html_id
  after_save :update_cache_chain
  before_destroy :update_cache_chain
  
  # Global method to trigger caching updates for all objects that rely on this object's information
  # This will be called in one of two cases:
  #   1) This object has changed, and effected cached objects need to recache
  #   2) An object has notified this object that it needs to recache 
  def update_cache_chain
    logger.debug "DB ********** Touching Element #{id} ********** "
    self.touch
    self.dynamic_page.try(:update_cache_chain)
  end


  # Scopes

  # Returns the elements ordered from highest (first) to lowest (last)
  scope :elem_order, order('position asc')
  # Returns all Elements with the position passed in
  scope :page_area_elems, lambda {|page_area|
    where(:page_area => page_area)
  }
  # Returns the ordered elements for the passed in position
  scope :elements_for_page_area, lambda {|page_area|
    page_area_elems(page_area).elem_order
  }
  # Returns the next highest available column_order number for the passed in position
#  def self.set_highest_column_order(position)
#    col_order = 1 + Element.position_elems(position).maximum("column_order")
#    col_order
#  end


  def create_html_id
    self.html_id = title.blank? ? "element-unnamed" :  title.downcase.gsub!(/[^a-zA-Z0-9\-_]+/, '-')
  end

  # Select array
  def self.get_elem_select
    ELEM_TYPES
  end

  # Returns the string name of the elem controller
  def get_elem_controller
    elem_type.tableize
  end

  
end
