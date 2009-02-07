require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'

ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection('test')
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

load(File.dirname(__FILE__) + "/schema.rb")

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'magic_cache_keys'

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
 
class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end
 
  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false
 
  # Add more helper methods to be used by all tests here...
end
