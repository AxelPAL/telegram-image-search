require 'active_record'
require 'yaml'
require 'zlib'

@db_config = YAML::load(File.open(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.establish_connection(@db_config['default'])