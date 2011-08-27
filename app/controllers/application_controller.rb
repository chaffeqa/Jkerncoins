class ApplicationController < ActionController::Base
  include ApplicationHelper
  
  protect_from_forgery
  rescue_from ActiveRecord::RecordNotFound, :with => :error_rescue
  rescue_from ActionController::RoutingError, :with => :error_rescue
  
  before_filter :get_home_node  
  
  helper :all
  helper_method :get_node, :categories_for_items, :get_home_node, :admin?
  layout 'static_page'

  def categories_for_items(items = Item.all)
    (items.collect {|item| item.categories }).uniq.compact
  end

  def get_home_node
    @home_node ||= Node.home
    return @home_node
  rescue ActiveRecord::RecordNotFound
    create_home_node
    return @home_node
  end


  def get_node
    # If /:shortcut is blank, then default to the Home page
    @shortcut ||= params[:shortcut].blank? ? @home_node.shortcut : params[:shortcut]
    @node ||= Node.find_shortcut(@shortcut)
    redirect_to(error_path(:shortcut => @shortcut )) unless @node
    @node
  end

  #TODO
  def admin?
    admin_signed_in? || Rails.env.development?
  end

  def check_admin
    unless admin?
      redirect_to error_path(:message => 'Unauthorized Access')
    end
  end
  
  # Renders our error pages, with passed in status and log message.  Returns false
  def render_error_status(status=500, log_msg = "")
    logger.error "REQUEST **************** Rendering #{status}: #{log_msg}. Request URI: #{request.url} ****************"
    render :file => "#{Rails.root}/public/#{status}.html", :status => status, :layout => false
    return false
  end



  private

  def create_home_node
    home_page = DynamicPage.create(:template_name => 'Home')
    @home_node = home_page.create_node(:menu_name => 'Home', :title => 'Home', :shortcut => 'Home', :displayed => true)
  end

  # Renders a 404 page if an active record error occurs
  def error_rescue(exception = nil)
    return render_error_status(404, exception.message)
  end


end

