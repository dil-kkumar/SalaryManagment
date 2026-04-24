Rails.application.routes.draw do
  get '/health', to: proc { [200, { 'content-type' => 'application/json' }, ['{"status":"ok"}']] }

  namespace :api do
    namespace :v1 do
      resources :employees do
        collection do
          post :import
          get :import_template
          get :export
        end
      end
      resources :country_custom_fields, only: %i[index create update destroy]
      resources :static_data, only: [:index]

      namespace :insights do
        get :summary
        get :salary_stats
        get :title_salary
        get :department_stats
        get :department_employee_counts
        get :top_earners
        get :salary_distribution
      end
    end
  end
end
