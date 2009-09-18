namespace :db do
  desc 'Load initial application data'
  task :load_data do
    require 'active_record'
    ActiveRecord::Base.configurations = Rails::Configuration.new.database_configuration
  end
end

