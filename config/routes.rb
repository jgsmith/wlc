ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  map.resources :semesters, :shallow => true do |semester|
    semester.resources :courses do |course|
      course.resource  :course_participants, :as => 'roster'
      course.resources :rubrics do |rubric|
        rubric.resources :prompts do |prompt|
          prompt.resources :responses
        end
      end
      course.resources :assignments do |assignment|
        assignment.resources :messages
        assignment.resources :assignment_modules, :as => 'timeline'
        assignment.resource  :author_eval
        assignment.resource  :grades
        assignment.resources :assignment_submissions, :as => 'participants' do |participant|
          participant.resources :messages
          participant.resource  :instructor_eval
        end
        #assignment.resource  :assignment_participants, :as => 'participants'
        assignment.resources :assignment_participations do |participation|
          participation.resources :messages
          participation.resources :uploads
          participation.resource  :author_eval
          participation.resource  :participant_eval
        end
      end
    end
  end


  map.resources :module_defs, :shallow => true do |module_def|
    module_def.resources :state_defs do |state_def|
      state_def.resources :transition_defs
    end
  end

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  map.root :controller => "main"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
