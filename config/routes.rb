ExpiryManagerExample::Application.routes.draw do
  match 'part1/:action', :controller => :part1

  root :to => 'part1#index'
end
