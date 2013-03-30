module ExpiryMapping
  # Look for user_id in cache name (users are not used in demo)
  CURRENT_USER = "CURRENT_USER"#<= Must be a string
  
  # controller to hash mappings, controller and action regex is supported
  def ExpiryMapping.cache_hash
    {
      'part1' => {
        :expire_do_action1 =>  [
          # Expire these cache names
          [:do_action1],
        ],
        
        :expire_do_action2 =>  [
          [:do_action2],
        ],
        
        :expire_do_action3 =>  [
          [:do_action3],
        ],
        
        /expire_all/ => [method(:expire_all)]
      }
    }
  end
  
  # When the previous controller and action called expire the fragments
  def ExpiryMapping.last_request_hash
    {
      /fulfillment\// => {
        :show =>  [method(:when_leaving_fulfillment)],
        :index =>  [method(:when_leaving_fulfillment)]
      },
      
      'admin/users' => {
        :update => [method(:after_setting_user_permissions)]
      }
    }
  end
end

def expire_all(params, user_id, previous_params, expire, expire_all)
  expire_all.call
end
