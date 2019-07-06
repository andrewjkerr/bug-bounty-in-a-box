require 'httparty'
require 'logger'
require 'sinatra'
require 'sinatra/multi_route'
require 'singleton'
require 'yaml'

require_relative 'helpers/config.rb'
require_relative 'helpers/payload.rb'
require_relative 'helpers/request.rb'
require_relative 'helpers/slack.rb'

# An array of every HTTP method that multi_route supports.
#
# Example usage: `route *ALL_HTTP_METHODS '/example' do`
#
# @return [Array<Symbols>] All of the HTTP methods.
ALL_HTTP_METHODS = [
    :get,
    :post,
    :patch,
    :put,
    :delete,
    :head,
    :options,
]

# The default config file location.
#
# @return [String] The default config file location.
DEFAULT_CONFIG_FILE = 'config/application.yml'

# Execute this method before any request! Currently all this does is
# log the request to our request log.
before do
    load_configuration!
    @incoming_request = Request.new(request)
    @incoming_request.log!
end

# GET /
#
# A nice lil' "Hello world!" index.
#
# Example: GET /
get '/' do
    'Hello world!'
end

# GET, POST, PUT/PATCH, DELETE, OPTIONS /callback
#
# A callback route that:
# 1. Logs the callback parameters
# 2. Alerts in Slack
#
# Required parameters:
#
# Optional parameters:
#
# Example: GET /callback
route *ALL_HTTP_METHODS, '/callback' do
    payload = Payload::create_payload_from_request_parameters(params)
    payload.log! unless payload.nil?
    "Callback successful!\n"
end

# GET, POST, PUT/PATCH, DELETE, OPTIONS /redirect
#
# A callback route that:
# 1. Logs the callback parameters
# 2. Alerts in Slack
#
# Required parameters:
# * `redirect`: The URL to redirect to.
#
# Optional parameters:
#
# Example: GET /redirect?redirect=https://www.example.com
route *ALL_HTTP_METHODS, '/redirect' do
    halt 400, "Empty redirect parameter" if params['redirect'].nil?
    redirect params['redirect']
end

helpers do

    # Loads our configuration file into environment variables for use later.
    #
    # @return [Void]
    def load_configuration!
        config_file_location = DEFAULT_CONFIG_FILE
        config_file_location = ARGV[1] unless ARGV[1].nil?

        begin
            config_file = File.read(config_file_location)
        rescue Exception => e
            puts "Oops, the config file does not exist: #{config_file_location}"
            raise e
        end

        Config.instance.load!(config_file)
    end
end
