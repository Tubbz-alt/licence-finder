require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each, type: :request) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
