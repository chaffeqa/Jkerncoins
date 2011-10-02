class Admin::ItemsController < ApplicationController
  helper_method :sort_column, :sort_direction
  layout 'admin'
  before_filter :check_admin
  before_filter :persist_filter_parameters

  def index
    @items = Item.scoped
    @items = @items.scope_display(@full_params[:displayed]) unless @full_params[:displayed].blank?
    @items = @items.scope_for_sale(@full_params[:for_sale]) unless @full_params[:for_sale].blank?
    @items = @items.scope_category(@full_params[:category]) unless @full_params[:category].blank?
    @items = @items.scope_name(@full_params[:name]) unless @full_params[:name].blank?
    @items = @items.scope_item_id(@full_params[:item_id]) unless @full_params[:item_id].blank?
    @items = @items.scope_max_price(@full_params[:max_price]) unless @full_params[:max_price].blank?
    @items = @items.scope_min_price(@full_params[:min_price]) unless @full_params[:min_price].blank?
    @items = @items.paginate :page => @full_params[:page], :per_page => @full_params[:per_page], :order => (sort_column + " " + sort_direction)
  end

  def sort_alphanumerically
    if request.post?
      Category.all.each do |cat|
        item_nodes = cat.node.children.items.collect {|n| n }
        unless item_nodes.empty?
          item_nodes.sort_by {|node| node.title }.each_with_index do |node, i|
            Node.update_all(['position = ?', i], ['id = ?', node.id]) unless node.position == i
          end
        end
      end
      @home_node.touch
    end
    redirect_to admin_items_path, :notice => "Items Successfully Sorted Alphanumerically!"
  end


  def new
    session[:last_view] = request.env["HTTP_REFERER"] || admin_items_url
    logger.debug "************ CODE **************\nSaved session 'last_view': #{session[:last_view]}\n************ END **************"
    @item = Item.new
    @item.nodes.build(:displayed => true) unless @item.nodes.count > 0
  end

  def edit
    session[:last_view] = request.env["HTTP_REFERER"] || admin_items_url
    logger.debug "************ CODE **************\nSaved session 'last_view': #{session[:last_view]}\n************ END **************"
    @item = Item.find(params[:id])
    @item.nodes.build(:displayed => true) unless @item.nodes.count > 0
  end

  def create
    @item = Item.new(params[:item])
    if @item.save
      #redirect_to(admin_items_path, :notice => 'Item was successfully created.')
      redirect_to(session[:last_view], :notice => 'Item was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    @item = Item.find(params[:id])
    if @item.update_attributes(params[:item])
      #redirect_to(admin_items_path, :notice => 'Item was successfully updated.')
      redirect_to(session[:last_view], :notice => 'Item was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @item = Item.find(params[:id])
    @item.destroy
    puts "******************** #{ (true && request.referer =~ /items/).to_s}"
    flash.notice = 'Item was successfully destroyed.'
    if request.referer =~ /items/
      redirect_to(admin_items_path)
    else
      redirect_to root_path
    end
  end

  # CRUD operation
  def reset_filters
    if request.post?
      cookies.delete(:name)
      cookies.delete(:item_id)
      cookies.delete(:displayed)
      cookies.delete(:for_sale)
      cookies.delete(:min_price)
      cookies.delete(:max_price)
      cookies.delete(:category)
      cookies.delete(:sort)
      cookies.delete(:direction)
    end
    redirect_to(admin_items_url)
  end

  private

  # Creates the @full_params object which contains all the applied filters
  def persist_filter_parameters
    create_params_cookies
    @full_params = {}
    @full_params[:name]=cookies[:name] unless cookies[:name].blank?
    @full_params[:item_id]=cookies[:item_id] unless cookies[:item_id].blank?
    @full_params[:displayed]=cookies[:displayed] unless cookies[:displayed].blank?
    @full_params[:for_sale]=cookies[:for_sale] unless cookies[:for_sale].blank?
    @full_params[:min_price]=cookies[:min_price] unless cookies[:min_price].blank?
    @full_params[:max_price]=cookies[:max_price] unless cookies[:max_price].blank?
    @full_params[:category]=cookies[:category] unless cookies[:category].blank?
    @full_params[:sort]=cookies[:sort] unless cookies[:sort].blank?
    @full_params[:direction]=cookies[:direction] unless cookies[:direction].blank?
    @full_params[:page]=cookies[:page] unless cookies[:page].blank?
    @full_params[:per_page]= cookies[:per_page]
  end

  # Creates/Updates the cookies values based on past and new filter parameters
  def create_params_cookies
    cookies[:name]={ :expires => 5.minutes.from_now, :value => params[:name] } unless params[:name].nil?
    cookies[:item_id]={ :expires => 5.minutes.from_now, :value => params[:item_id] } unless params[:item_id].nil?
    cookies[:displayed]={ :expires => 5.minutes.from_now, :value => params[:displayed] } unless params[:displayed].nil?
    cookies[:for_sale]={ :expires => 5.minutes.from_now, :value => params[:for_sale] } unless params[:for_sale].nil?
    cookies[:min_price]={ :expires => 5.minutes.from_now, :value => params[:min_price] } unless params[:min_price].nil?
    cookies[:max_price]={ :expires => 5.minutes.from_now, :value => params[:max_price] } unless params[:max_price].nil?
    cookies[:category]={ :expires => 5.minutes.from_now, :value => params[:category] } unless params[:category].nil?
    cookies[:sort]={ :expires => 5.minutes.from_now, :value => params[:sort] } unless params[:sort].nil?
    cookies[:page]={ :expires => 5.minutes.from_now, :value => params[:page] } unless params[:page].nil?
    cookies[:direction]={ :expires => 5.minutes.from_now, :value => params[:direction] } unless params[:direction].nil?
    cookies[:per_page]={ :expires => 5.minutes.from_now, :value => params[:per_page] } unless params[:per_page].nil?
    cookies[:per_page]={ :expires => 5.minutes.from_now, :value => 10 } if cookies[:per_page].blank?
  end

  def sort_column
    @sort = @sort || cookies[:sort] || ''
    Item.column_names.include?(@sort) ? @sort : "name"
  end

  def sort_direction
    @direction = @direction || cookies[:direction] || ''
    "ASC DESC".include?(@direction) ? @direction : "ASC"
  end

end

