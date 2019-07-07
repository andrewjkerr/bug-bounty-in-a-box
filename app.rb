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

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /callback
#
# A callback route that:
# 1. Logs the callback parameters
# 2. Alerts in Slack
route *ALL_HTTP_METHODS, '/callback' do
    payload = Payload::create_payload_from_request_parameters(params)
    payload.log! unless payload.nil?
    "Callback successful!\n"
end

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /js
#
# A route that returns a JavaScript payload file.
route *ALL_HTTP_METHODS, '/js' do
    # Build our callback query string.
    query_string = '?payload=js_file'

    # Add a target if we have one.
    query_string += "&target=#{URI::encode(params['target'])}" unless params['target'].nil?

    # And, finally, build the callback URL!
    @callback_url = Config.instance.application_url + '/callback' + query_string

    # Set the Content-Type header.
    headers['Content-Type'] = ContentType::JAVASCRIPT + '; charset=UTF-8'

    # Render our payload.
    renderer = ERB.new(File.read('templates/payload.js.erb'))
    renderer.result(binding)
end

# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /redirect
#
# Redirects to the URL specified in the "redirect" parameter.
#
# Required parameters:
# * `redirect`: The URL to redirect to.
route *ALL_HTTP_METHODS, '/redirect' do
    halt 400, 'Empty redirect parameter' if params['redirect'].nil?
    redirect params['redirect']
end


# GET, POST, PUT/PATCH, DELETE, HEAD, OPTIONS /js
#
# A route that returns a JavaScript payload file.
route *ALL_HTTP_METHODS, '/svg' do
    # Build our callback query string.
    query_string = '?payload=svg_file'

    # Add a target if we have one.
    query_string += "&target=#{URI::encode(params['target'])}" unless params['target'].nil?

    # And, finally, build the callback URL!
    @callback_url = Config.instance.application_url + '/callback' + query_string

    # Set the Content-Type header.
    headers['Content-Type'] = ContentType::SVG + '; charset=UTF-8'

    # Render our payload.
    renderer = ERB.new(File.read('templates/payload.svg.erb'))
    renderer.result(binding)
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
