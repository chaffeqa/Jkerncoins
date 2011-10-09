class ShortcutController < ApplicationController
  before_filter :check_shortcut, :only => :route
  #caches_action :route , :unless => Proc.new { |c| admin? }, :cache_path => Proc.new { |c|c.send(:shortcut_path, @node.id)}

  def route
    if @node.page_type == 'DynamicPage'
      if params[:fresh].present? or admin? or not PAGE_MEMCACHE_CACHING
        render("#{@node.page_type.tableize.pluralize}/show", :layout => "dynamic")
      else
        render_with_cache('node-page::'+request.fullpath+'::'+@node.cache_key) {
          render("#{@node.page_type.tableize.pluralize}/show", :layout => "dynamic")
        }
      end
    else
      if @node and @node.page_type and @node.page
        if params[:fresh].present? or admin?
          render("#{@node.page_type.tableize.pluralize}/show")
        else
          render_with_cache('node-page::'+request.fullpath+'::'+@node.cache_key) {
            render("#{@node.page_type.tableize.pluralize}/show")
          }
        end
      else
        return error_redirect
      end
    end
  end

  def error
    return head(:status => 404) unless request.format == :html
    @message = params[:message]
    @shortcut = params[:shortcut]
    unless @shortcut.blank?
      @similar_nodes = Node.displayed.where(["UPPER(shortcut) LIKE UPPER(?)", "%"+@shortcut+"%"])
    end
    render('error_page/error', :format => :html)
  end






  private

  def error_redirect(message="The page you have requested either has been moved or doesn't exit.")
    shortcut = params[:shortcut].blank? ? nil : params[:shortcut]
    redirect_to(error_path(:message => message, :shortcut => shortcut))
    return false
  end

  def check_shortcut
    unless get_node.nil?
      # Error for a non-displayed page request
      error_redirect() unless request.format == :html
      error_redirect('The ' + @node.page_type.capitalize || 'page' + ' you are trying to view is no longer publicly listed.') if @node and not @node.displayed and not admin?
    end
  end

end

