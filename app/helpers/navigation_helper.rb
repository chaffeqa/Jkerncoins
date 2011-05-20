module NavigationHelper
  
  # Overrides the render_navigation call in order to render site specific structure and add :flat => true capability
  # as well as caching capability
  def render_navigation(options={})
    flat = options.delete(:flat) || false
    if @home_node
      key = flat ? "flat-tree::#{@home_node.cache_key}" : "tree::#{@home_node.cache_key}"
      cached = Rails.cache.read(key)
      if cached
        logger.debug "CACHE **************** Read Cache key: #{key.to_s} ****************"
        items = cached
      else
        logger.debug "CACHE **************** Write Cache key: #{key.to_s} ****************"
        items = (flat ? @home_node.flat_node_tree : @home_node.node_tree)
        Rails.cache.write(key, items) if cached.nil?
      end
      return raw(super(options.merge({:items => items})))
    end
    return ""
  end
end
