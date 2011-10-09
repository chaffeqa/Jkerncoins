module NavigationHelper

  # Overrides the render_navigation call in order to render site specific structure and add :flat => true capability
  # as well as caching capability
  def render_navigation(options={})
    logger.error "render_navigation CAAAAAAALLED FROM: #{caller.inspect}"
    return ""
  end



  def breadcrumb_for(node)
    (node.ancestors.map {|pnode| pnode.html_link } << node.html_link).join(" &gt; ").html_safe
  end
end
