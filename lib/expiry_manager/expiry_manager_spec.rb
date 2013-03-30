load 'expiry_manager.rb'

# A few notes
# * I am not using should receive for checking method receptions because I am assuming the worst case; that
#   the method (really a function in this case) is unrelated to any custom object.
# * I occassionally use a string instead of a symbol for hash keys. This is because the expiry manager should
#   shouldn't care if the strings in the hash are symbols or not.
describe ExpiryManager::Manager do
  def expire_method
  end
  def expire_all_method
  end
  
  describe "init" do
    before(:each) do
      ExpiryManager::Manager.stub!(:expire_fragments)
    end
    
    it "should raise an Argument Error if nothing is sent" do
      expect{ ExpiryManager::Manager.new }.to raise_error(ArgumentError)
    end
    
    it "should raise an Argument Error if one argument is sent" do
      expect{ ExpiryManager::Manager.new {} }.to raise_error(ArgumentError)
    end
    
    it "should raise an Argument Error if two arguments are sent" do
      expect{ ExpiryManager::Manager.new({}, 1,  method(:expire_method))}.to raise_error(ArgumentError)
    end
    
    
    it "should raise an Argument Error if a closure isn't sent as a second method" do
      expect{ ExpiryManager::Manager.new({}, 1, 'here', 'here')}.to raise_error(ArgumentError)
    end
    
    it "should raise an Argument Error if a closure isn't sent as a third method" do
      expect{ ExpiryManager::Manager.new({}, 1, expire_method, 'here')}.to raise_error(ArgumentError)
    end
    
    it "should set user to -1 if no user_id is sent in" do
      em = ExpiryManager::Manager.new({}, nil, method(:expire_method), method(:expire_method))
      em.instance_variable_get(:@user).should == "-1"
    end
    
    it "should save the sent in params and closure" do
      mr_hash = {"italian_guy_says" => "no_dice"}
      
      em = ExpiryManager::Manager.new mr_hash, 1, method(:expire_method), method(:expire_all_method)
      em.instance_variable_get(:@expire).should == method(:expire_method)
      em.instance_variable_get(:@expire_all).should == method(:expire_all_method)
      em.instance_variable_get(:@params).should == mr_hash
      em.instance_variable_get(:@user).should == "1"

    end
  end
  
  describe "expire_fragments" do
    def expire_method(arg)
      @expired_got.push arg
    end
    
    def expire_all_method()
      @expired_all_got += 1
    end
    
    before(:each) do
      @expired_got = []
      @expired_all_got = 0
      
      
      ExpiryMapping.stub!(:cache_hash).and_return({
        'controller/location' => {
          :do_this => [
                      :expire_fragment_1,
                      :expire_fragment_2
                    ],
          :and_this => [
                      :expire_fragment_3,
                      :expire_fragment_4
                    ]
        },
        /other/ => {
          :do_this => [
                      :expire_fragment_5,
                      :expire_fragment_6
                    ],
          :and_this => [
                      :expire_fragment_7,
                      :expire_fragment_8
                    ]
        },
        /weird/ => {
          /weird/ => [
                      :expire_fragment_9,
                      :expire_fragment_10
                    ],
          :try_this => [
                      :expire_fragment_11,
                      :expire_fragment_12
                    ]
        }
      })
      ExpiryMapping.stub!(:last_request_hash).and_return({
        'controller/location2' => {
          :do_this2 => [
                      :expire_fragment_9,
                      :expire_fragment_10
                    ],
          :and_this2 => [
                      :expire_fragment_11,
                      :expire_fragment_12
                    ]
        }
      })
      
      valid_params = {:action => ExpiryMapping.cache_hash['controller/location'].keys[0], :controller => 'controller/location'}
      @em = ExpiryManager::Manager.new valid_params, 1, method(:expire_method), method(:expire_all_method)
    end
    
    it "should not expire all actions when the previous action is not nil" do
      @em.previous_action = {:action =>"no", :controller => "action"}
      
      @em.expire_fragments
      @expired_all_got.should == 0
    end
    
    it "should call the expire callback with the fragment corresponding to the controller action for the CACHE_HASH" do
      @em.previous_action = {:action =>"no", :controller => "action"}
      
      @em.expire_fragments
      @expired_got.should == ExpiryMapping.cache_hash['controller/location'].values[0]
    end
    
    it "should call the expire callback with the fragment corresponding to the controller action for the previous url" do
      @em.previous_action = {:action => ExpiryMapping.last_request_hash.values[0].keys[0], :controller => ExpiryMapping.last_request_hash.keys[0]}
      @em.expire_fragments
      
      @expired_got.should =~ ExpiryMapping.last_request_hash['controller/location2'].values[0] + ExpiryMapping.cache_hash['controller/location'].values[0]
    end
    
    context "regex" do
      it "should call the expire call back with all fragments that match a controllers regex" do
        valid_params = {:action => "do_this", :controller => "the other controller"}
        @em = ExpiryManager::Manager.new valid_params, 1, method(:expire_method), method(:expire_all_method)
        
        @em.previous_action = {:action => "no", :controller => "action"}
        @em.expire_fragments
        
        @expired_got.should == [:expire_fragment_5, :expire_fragment_6]
      end
      
      it "should call the expire call back with all fragments that match a controllers regex and one of its actions regex" do
        valid_params = {:action => "weird action", :controller => "weird controller"}
        @em = ExpiryManager::Manager.new valid_params, 1, method(:expire_method), method(:expire_all_method)
        
        @em.previous_action = {:action => "no", :controller => "action"}
        @em.expire_fragments
        
        @expired_got.should == [:expire_fragment_9, :expire_fragment_10]
      end
    end
    
    context "closures" do
      def custom_method1(params, user_id, previous_params, expire, expire_all)
        @custom_method1_got.push [params, user_id, previous_params, expire, expire_all]
        expire.call :custom_fragment1
        expire.call :custom_fragment2
      end
      def custom_method2(params, user_id, previous_params, expire, expire_all)
        @custom_method2_got.push [params, user_id, previous_params, expire, expire_all]
        expire_all.call
      end
      
      def prepare_for_expire
        @valid_params = {:action => :take_out_lmaoplane, :controller => "roflcopter"}
        @previous_params = {:action => "no", :controller => "action"}
        @em = ExpiryManager::Manager.new @valid_params, 1, method(:expire_method), method(:expire_all_method)
        
        @em.previous_action = @previous_params
        @em.expire_fragments
      end
      
      before(:each) do
        @custom_method1_got = []
        @custom_method2_got = []
        
        ExpiryMapping.stub!(:cache_hash).and_return({
          "roflcopter" => {
            :take_out_lmaoplane => [
              method(:custom_method1),
              :fragment14,
              method(:custom_method2)
            ]
          }
        })
      end
        
      it "should call custom methods with right params sent in" do
        prepare_for_expire
        @custom_method1_got.should == [[@valid_params, "1", @previous_params, @em.expire, @em.expire_all]]
        @custom_method2_got.should == [[@valid_params, "1", @previous_params, @em.expire, @em.expire_all]]
      end
      
      it "should expire fragments specified by the custom functions and by the fragment names" do
        prepare_for_expire
        @expired_got.should =~ [:fragment14, :custom_fragment1, :custom_fragment2]
        @expired_all_got.should == 1
      end
    end
    
    context "multiple key caching" do
      before(:each) do
        @user = 12345
        
        ExpiryMapping.stub!(:cache_hash).and_return({
          "session" => {
            :new => [
              ["test", "first_set", "first"],
              ["test", "first_set", "first"],
              ["test", "second_set", "first"]
            ]
          },
          
          "admin" => {
            :update_user => [
              [ExpiryMapping::CURRENT_USER, "first_set", "first"],
              ["test", ExpiryMapping::CURRENT_USER, "first"],
              ["test", "second_set", ExpiryMapping::CURRENT_USER]
            ]
          }
        })
      end
      
      it "should send in list of keys to expire when expire is sent" do
        @valid_params = {:action => "new", :controller => "session"}
        @previous_params = {:action => "no", :controller => "action"}
        @em = ExpiryManager::Manager.new @valid_params, @user, method(:expire_method), method(:expire_all_method)
        @em.previous_action = @previous_params
        
        @em.expire_fragments
        @expired_got.should =~ [["test", "first_set", "first"], ["test", "first_set", "first"], ["test", "second_set", "first"]]
      end
      
      it "should replace the current user specifier in the list and then send it to expire when expire is sent" do
        @valid_params = {:action => "update_user", :controller => "admin"}
        @previous_params = {:action => "no", :controller => "action"}
        @em = ExpiryManager::Manager.new @valid_params, @user, method(:expire_method), method(:expire_all_method)
        @em.previous_action = @previous_params
        
        @em.expire_fragments
        @expired_got.should == [[@user.to_s, "first_set", "first"], ["test", @user.to_s, "first"], ["test", "second_set", @user.to_s]]
      end
    end
  end
  
  describe "path_matcher" do
    def expire_method(arg)
      @expired_got.push arg
    end
    
    before(:each) do
      ExpiryManager::Manager.stub!(:expire_fragments)
      
      @expired_got = []
      
      ExpiryMapping.stub!(:cache_hash).and_return({
        '*' => {
          :do_this => [
                      :expire_fragment_1,
                      :expire_fragment_2
                    ],
          :and_this => [
                      :expire_fragment_3,
                      :expire_fragment_4
                    ]
        },
        
        /good/ => {
          :action3 => [
            :expire_fragment_5,
            :expire_fragment_6
          ]
        },
        
        /od\/pa/ => {
          :action4 => [
            :expire_fragment_7,
            :expire_fragment_8
          ]
        },
        
        'good/path' =>{
          :action5 => [
            :expire_fragment_8,
            :expire_fragment_9
          ]
        },
        
        'other/path' =>{
          :action6 => [
            :expire_fragment_10,
            :expire_fragment_11
          ]
        },
        
        'in soviet russia' => {:fragment => [:expires_you]}
      })
      
      valid_params = {:action => ExpiryMapping.cache_hash.values[0].keys[0], :controller => ExpiryMapping.cache_hash.keys[0]}
      @em = ExpiryManager::Manager.new valid_params, 1, method(:expire_method), method(:expire_all_method)
    end
    
    context "* matching" do
      it "should not  get anything when * is not defined in the regex matcher and it matches none of the regexes" do
        @em.path_matcher({'epic' => 'hash'}, 'reprasentin').should == []
      end
      
      it "should get elements under * with any controller path when * is defined in the hash that is searched" do
        @em.path_matcher(ExpiryMapping.cache_hash, '*').include?(ExpiryMapping.cache_hash["*"]).should be_true
        @em.path_matcher(ExpiryMapping.cache_hash, 'reprasentin').include?(ExpiryMapping.cache_hash["*"]).should be_true
        @em.path_matcher(ExpiryMapping.cache_hash, 'my\/ridiculous///controller//path').include?(ExpiryMapping.cache_hash["*"]).should be_true
      end
      
      it "should get elements under * with any controller path when * is defined in the hash that is searched" do
        @em.path_matcher(ExpiryMapping.cache_hash, '*').include?(ExpiryMapping.cache_hash["*"]).should be_true
        @em.path_matcher(ExpiryMapping.cache_hash, 'reprasentin').include?(ExpiryMapping.cache_hash["*"]).should be_true
        @em.path_matcher(ExpiryMapping.cache_hash, 'my\/ridiculous///controller//path').include?(ExpiryMapping.cache_hash["*"]).should be_true
      end
    end
  
    context "regex matching" do
      it "should get none of the sets of elements when the mapping hash is empty" do
        @em.path_matcher({}, 'good/path').should == []
      end
      
      it "should get the sets of values that the string matches" do
        @em.path_matcher(ExpiryMapping.cache_hash, 'other/path').should =~ [ExpiryMapping.cache_hash["*"], ExpiryMapping.cache_hash['other/path']]
      end
      
      it "should get the sets of values of the keys that the controller_path matches and the strings matches [single]" do
        @em.path_matcher(ExpiryMapping.cache_hash, 'od/park').should =~ [ExpiryMapping.cache_hash[/od\/pa/], ExpiryMapping.cache_hash["*"]]
      end
      
      it "should get the sets of values of the keys that the controller_path matches and the strings matches [multiple]" do
        @em.path_matcher(ExpiryMapping.cache_hash, 'good/path').should =~ [ExpiryMapping.cache_hash[/good/], ExpiryMapping.cache_hash[/od\/pa/], ExpiryMapping.cache_hash["*"], ExpiryMapping.cache_hash['good/path']]
      end
    end
    
  end
  
  describe "debug_mode" do
    def fake_method
    end
    
    before(:each) do
      ExpiryMapping.stub!(:cache_hash).and_return({})
    end
    
    it "should call print_matches when debug mode is on" do
      em = ExpiryManager::Manager.new({}, 1, method(:fake_method), method(:fake_method))
      em.debug_mode = true
      
      em.should_receive(:print_matches)
      em.expire_fragments
    end
  
    it "should call print_matches when debug mode is on" do
      em = ExpiryManager::Manager.new({}, 1, method(:fake_method), method(:fake_method))
      
      em.should_not_receive(:print_matches)
      em.expire_fragments
    end
    
  end
end
