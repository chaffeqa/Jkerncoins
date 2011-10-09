# Load the rails application
require File.expand_path('../application', __FILE__)



MODEL_CACHING = false
PAGE_MEMCACHE_CACHING = true
VIEW_FRAGMENT_CACHING = false

# Initialize the rails application
KernCoinProject::Application.initialize!
