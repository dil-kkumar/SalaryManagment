Rails.application.routes.draw do
  get '/health', to: proc { [200, { 'Content-Type' => 'application/json' }, ['{"status":"ok"}']] }

  namespace :api do
    namespace :v1 do
      resources :employees

      namespace :insights do
        get :summary
        get :salary_stats
        get :title_salary
        get :department_stats
        get :top_earners
        get :salary_distribution
      end
    end
  end
end
