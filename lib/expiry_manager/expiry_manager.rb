#require 'ruby-debug'
load 'expiry_mapping.rb'

module ExpiryManager
  include ExpiryMapping
  
  # Handles expiry of caches by using the current and previous action in conjunction with its
  # corresponding hashes
  class Manager
    MATCH_ALL_ALIAS = "*"
    
    attr_accessor :previous_action, :expire, :expire_all, :debug_mode
    
    def initialize(params, user_id, expire_callback, expire_all_callback)
      raise ArgumentError, "One or more arguments was not present or was nil" if params.nil? or expire_callback.nil?
      raise ArgumentError, "The second and third arguments must be closures" unless expire_callback.respond_to? :call
      
      @params = params
      @user = "-1"
      @user = user_id.to_s unless user_id.nil?
      @expire = expire_callback
      @expire_all = expire_all_callback
      @previous_action = nil
      @debug_mode = false
    end
    
    # Using the sent in controller and action and expires the specified fragments using the @expire method.
    def expire_fragments
      expire_fragments_for ExpiryMapping.cache_hash, @params
      expire_fragments_for ExpiryMapping.last_request_hash, @previous_action unless @previous_action.nil?
      
      return nil#Haven't decided on appropriate return yet
    end
    
    # Expires all fragments specified by _hash. When a function is encountered calls the function
    # sending in controller+action of the current action (if in the previous action hash sends in previous
    # action), the controller+action of the previous action, and the expire and expire all methods.
    def expire_fragments_for(_hash, using_hash)
      matches = path_matcher(_hash, using_hash[:controller])
      print_matches matches, "controller_matches" if @debug_mode
      
      matches.each do |match|
        fragments = path_matcher(match, using_hash[:action]).flatten(1)
        print_matches fragments, "action_matches" if @debug_mode
        
        fragments.each do |fragment|
          fragment.each_with_index{|part, i| fragment[i].to_s.gsub!(ExpiryMapping::CURRENT_USER.to_s, @user)} if fragment.kind_of?(Array)
          
          if fragment.respond_to? :call
            fragment.call @params, @user, @previous_action, @expire, @expire_all
          else
            @expire.call fragment
          end
        end
        
      end
    end
    
    # Matches the path to any keys in the hash, this includes regex matching. Then returns the values of the matched
    # keys in an array.
    def path_matcher(_hash, path)
      return [] if path.nil?
      
      matches = []
      matches.push _hash[MATCH_ALL_ALIAS] if _hash.include? MATCH_ALL_ALIAS
      
      # Add any string matched values
      matches.push _hash[path.to_s] unless _hash[path.to_s].nil?
      matches.push _hash[path.to_sym] unless _hash[path.to_sym].nil?
      
      # Add any hash values when their key regex matches the controller_path
      _hash.each_pair do |key, value|
        if key.is_a? Regexp and !path.is_a? Regexp
          matches.push value if path.match key# Note that nil is falsy
        end
      end
      
      return matches
    end
    
    def print_matches(matches, message)
      print "\n====================\n"
      print message + "\n"
      matches.each{|m| print "=> #{m.inspect} \n"}
      print "====================\n"
    end
    
  end
end
