# A lil' helper class for our payloads; either creating them or logging them.
class Payload
    # The default logging location.
    # @return [String] The default logging location.
    DEFAULT_LOGGING_LOCATION = 'logs/payloads.log'

    # The default logging rotation.
    # @return [String] The default logging rotation.
    DEFAULT_LOGGING_ROTATION = 'daily'

    # The required request paramters to construct a payload.
    # @return [Array] The required request parameters.
    REQUIRED_REQUEST_PARAMETERS = [
        'payload',
        'target',
    ]

    # The payload we're using.
    # @return [String] The payload.
    attr_accessor :payload

    # The target for our payload.
    # @return [String] The target.
    attr_accessor :target

    # Our payload logger.
    # @return [Logger] The logger.
    attr_accessor :logger

    # Creates a new Payload instance.
    #
    # @param payload [String] Our payload.
    # @param target [String] Our target.
    # @return [Payload] Our Payload instance.
    def initialize(payload, target)
        @payload = payload
        @target = target
        logging_configuration = Config.instance.logging_configuration('payload')
        @logger = Logger.new(logging_configuration[:file], logging_configuration[:rotate])
    end

    # Logs a payload & sends a Slack message.
    #
    # @return [Void]
    def log!
        Slack::send_attachment!(format_for_slack)
        @logger.info(summary)
    end

    def summary
        return "Payload '#{@payload}' fired for #{@target}"
    end

    # Creates a Payload instance from our request parameters.
    #
    # @param params [Array] Our request parameters.
    # @return [Payload, nil] The Payload instance or nil if the required parameters aren't there.
    def self.create_payload_from_request_parameters(params)
        # Our Payload args.
        args = []

        # Run through our required request parameters and return nil if any are missing.
        REQUIRED_REQUEST_PARAMETERS.each do |required_param|
            return nil if params[required_param].nil?
            args << params[required_param]
        end

        return Payload.new(*args)
    end

    private

        # Formats a payload for sending via Slack
        #
        # @return [Hash] Our Payload in Slack "attachment" format.
        def format_for_slack
            fields = [
                {
                    'title': 'Payload',
                    'value': @payload,
                    'short': false,
                },
                {
                    'title': 'Target',
                    'value': @target,
                    'short': false,
                }
            ]

            return Slack::format_attachment(summary, fields, Slack::LEVEL_HIGH)
        end
end
