# A lil' helper class for our incoming HTTP requests
class Request
    # The default logging location.
    # @return [String] The default logging location.
    DEFAULT_LOGGING_LOCATION = 'logs/requests.log'

    # The default logging rotation.
    # @return [String] The default logging rotation.
    DEFAULT_LOGGING_ROTATION = 'daily'

    # The current HTTP request we're using.
    # @return [Rack::Request] The request.
    attr_accessor :request

    # Our payload logger.
    # @return [Logger] The logger.
    attr_accessor :logger

    # Creates a new Payload instance.
    #
    # @param payload [String] Our payload.
    # @param target [String] Our target.
    # @return [Payload] Our Payload instance.
    def initialize(request)
        @request = request
        logging_configuration = Config.instance.logging_configuration('request')
        @logger = Logger.new(logging_configuration[:file], logging_configuration[:rotate])
    end

    # Logs a payload & sends a Slack message.
    #
    # @return [Void]
    def log!
        # Log the request to the requests log.
        @logger.info(summary)

        # Send it to Slack.
        Slack::send_attachment!(format_for_slack)
    end

    private

        # Formats a payload for sending via Slack
        #
        # @return [Hash] Our Payload in Slack "attachment" format.
        def format_for_slack
            # Send the request to Slack.
            slack_summary = "New request to hack @ ajoekerr"
            slack_attachment_fields = [
                {
                    'title': 'IP Address',
                    'value': request.ip,
                    'short': false,
                },
                {
                    'title': 'Headers',
                    'value': headers.map{ |k,v| "#{k}: #{v}"}.join("\n"),
                    'short': false,
                },
                {
                    'title': 'Parameters',
                    'value': params.map{ |k,v| "#{k}: #{v}"}.join("\n"),
                    'short': false,
                },
            ]

            # Add target information if we have it!
            unless params['target'].nil?
                slack_summary = "#{slack_summary} from #{params['target']}"
                slack_attachment_fields << {
                    'title': 'Target',
                    'value': params['target'],
                    'short': false,
                }
            end

            # Gotta keep it light & breezy, Peralta.
            slack_summary += "!"

            return Slack::format_attachment(slack_summary, slack_attachment_fields)
        end

        # Gets the headers from a request.
        #
        # @return [Hash] The headers from a request.
        def headers
            return @request.env.select { |k,v| k.start_with? 'HTTP_'}
        end

        # Gets the IP from a request.
        #
        # @return [String] The IP from a request.
        def ip
            return @request.ip
        end

        # Gets the params from a request.
        #
        # @return [Hash] The params from a request.
        def params
            return @request.params
        end

        # Gets the summary for the request for logging.
        #
        # @return [String]
        def summary
            return "IP: #{@request.ip}\tHeaders: #{headers}\tParameters: #{params}"
        end
end
