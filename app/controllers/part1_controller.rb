class Part1Controller < ApplicationController
  helper_method :do_action1, :do_action2, :do_action3
  
  def index
    @page_load_actions = self.methods.reject{ |method| !method.to_s.starts_with? "do_action" }
    @expire_actions = self.methods.reject{ |method| !method.to_s.starts_with? "expire_do_action"}.push "expire_all_actions"
  end
  
  [:do_action1, :do_action2, :do_action3].each do |method|
    define_method method do
      print "doing #{method}...\n"
      sleep(1)
      print "#{method} complete.\n"
      
      "#{method} contents"
    end
  end
  
  [:expire_do_action1, :expire_do_action2, :expire_do_action3].each do |method|
    define_method method do
      redirect_to :action => :index
    end
  end
  
  # Seperated from above so you can see a regex example in expiry_mapping
  def expire_all_actions
    redirect_to :action => :index
  end
end
