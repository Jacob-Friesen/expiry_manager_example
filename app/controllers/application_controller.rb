class ApplicationController < ActionController::Base
  require "expiry_manager"
  
  protect_from_forgery
  
  before_filter :invoke_expiry_manager
  
  def clear_entire_cache
    Rails.cache.clear
  end
  def invoke_expiry_manager
    expiry_manager = ExpiryManager::Manager.new params, nil, method(:expire_fragment), method(:clear_entire_cache)
    expiry_manager.expire_fragments
  end
end
