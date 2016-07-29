require_relative 'config/environment'

namespace :db do
  desc 'Migrate the database'
  task :migrate do
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
  end
end