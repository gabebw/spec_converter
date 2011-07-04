$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'spec_converter'
require 'tempfile'

RSpec.configure do |config|
  config.mock_with :mocha
  config.color_enabled = true
  config.formatter     = :documentation
end
