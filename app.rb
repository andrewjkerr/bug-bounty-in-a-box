require 'erb'
require 'httparty'
require 'logger'
require 'sinatra'
require 'sinatra/multi_route'
require 'singleton'
require 'uri'
require 'yaml'

require_relative 'helpers/config.rb'
require_relative 'helpers/content_type.rb'
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

# GET /
#
# A nice lil' "Hello world!" index.
#
# Example: GET /
get '/' do
    'Hello world!'
end

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /callback
#
# A callback route that:
# 1. Logs the callback parameters
# 2. Alerts in Slack
route *ALL_HTTP_METHODS, '/callback' do
    log_request!

    payload = Payload::create_payload_from_request_parameters(params)
    payload.log! unless payload.nil?
    "Callback successful!\n"
end

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /payload
#
# A route that returns a payload file.
#
# Required parameters:
# * `type`: The payload type (i.e. 'js').
# * `exploit`: The exploit type (i.e. 'xss').
#
# Example: GET /payload?type=js&exploit=xss&target=www.example.com
route *ALL_HTTP_METHODS, '/payload' do
    log_request!

    halt 400, 'No type provided.' if params['type'].nil?
    halt 400, 'No exploit provided.' if params['exploit'].nil?

    supported_payloads = {
        'xss' => [
            'js',
            'svg',
        ],
        'xxe' => [
            'xml',
        ]
    }

    if supported_payloads[params['exploit']].nil?
        halt 400, "Invalid exploit type provided: #{params['exploit']}"
    end

    unless supported_payloads[params['exploit']].include?(params['type'])
        halt 400, "Invalid type provided: #{params['type']}"
    end

    # Build our callback query string.
    query_string = "?payload=#{params['type']}_file"

    # Add a target if we have one.
    query_string += "&target=#{URI::encode(params['target'])}" unless params['target'].nil?

    # And, finally, build the callback URL!
    @callback_url = Config.instance.application_url + '/callback' + query_string

    # Set the Content-Type header.
    headers['Content-Type'] = ContentType.const_get(params['type'].upcase) + '; charset=UTF-8'

    # Render our payload.
    file_path = "templates/payloads/#{params['exploit']}/payload.#{params['type']}.erb"
    renderer = ERB.new(File.read(file_path))
    renderer.result(binding)
end

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /redirect
#
# Redirects to the URL specified in the "redirect" parameter.
#
# Required parameters:
# * `redirect`: The URL to redirect to.
route *ALL_HTTP_METHODS, '/redirect' do
    log_request!

    halt 400, 'Empty redirect parameter' if params['redirect'].nil?
    redirect params['redirect']
end

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /unauthorized
#
# A route that returns a 401 for a given content type. Will return 200 for OPTIONS & HEAD
# unless 'force_401' is set.
#
# Optional parameters:
# * `content_type`: The content type constant name in ContentType.
# * `force_401`: Should we force a 401 for OPTIONS & HEAD requests?
#
# Example: GET /unauthorized?content_type=audio_mpeg
route *ALL_HTTP_METHODS, '/unauthorized' do
    log_request!

    unless params['content_type'].nil?
        content_type_constant = params['content_type'].upcase
        if ContentType.const_defined?(content_type_constant)
            headers['Content-Type'] = ContentType.const_get(content_type_constant)
        end
    end

    # Special processing if it's an OPTIONS or a HEAD.
    if env['REQUEST_METHOD'] == 'OPTIONS' || env['REQUEST_METHOD'] == 'HEAD'
        halt 200, 'Ok' unless params['force_401']
    end

    # Return a 401 Unauthorized
    halt 401
end

helpers do
    # Logs an incoming request & sends a Slack message.
    #
    # @return [Void]
    def log_request!
        @incoming_request = Request.new(request)
        @incoming_request.log!
    end
end

##
# Load our configuration file!
#
# We do this when the server starts to catch any errors on startup. :)
##
config_file_location = DEFAULT_CONFIG_FILE
config_file_location = ARGV[0] unless ARGV[0].nil?

begin
    config_file = File.read(config_file_location)
rescue Exception => e
    puts "Oops, the config file does not exist: #{config_file_location}"
    raise e
end

# Load the config!
Config.instance.load!(config_file)
