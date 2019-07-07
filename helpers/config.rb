# A singleton Config class.
#
# Example usage:
# ```
# Config.instance.load!(File.open('config/application.yaml'))
# slack_url = Config.instance.slack_url
# logging_configuration = Config.instance.logging_configuration('classname')
# ```
class Config
    include Singleton

    # The application URL key for the configuration file.
    # @return [String] The application URL.
    APPLICATION_URL_KEY = 'application_url'

    # The Slack URL key for the configuration file.
    # @return [String] The Slack URL configuration key.
    SLACK_URL_KEY = 'slack_url'

    # The application configuration.
    #
    # @return [Hash<Mixed>] The application configuration.
    attr_accessor :config

    # Loads a config file.
    #
    # @raise [Exception] If the configuration file is invalid.
    #
    # @param config_file [String] The contents of the config file.
    # @return [Void]
    def load!(config_file)
        @config = YAML.load(config_file)

        # Ensure the Slack URL key is set.
        if @config[APPLICATION_URL_KEY].nil?
            raise Exception.new("Ruh roh, you need to define a an application URL using #{APPLICATION_URL_KEY} in your configuration!")
        end

        # Ensure the Slack URL key is set.
        if @config[SLACK_URL_KEY].nil?
            raise Exception.new("Ruh roh, you need to define a Slack endpoint using #{SLACK_URL_KEY} in your configuration!")
        end
    end

    # Returns the application URL from the configuration.
    #
    # @return [String] The application URL.
    def application_url
        raise Exception.new('You need to load the configuration before using it.') if @config.nil?

        return @config[APPLICATION_URL_KEY]
    end

    # Returns the logging configuration for a given log.
    #
    # Example usage:
    # ```
    # logging_configuration = Config.instance.logging_configuration('classname')
    # @logger = Logger.new(logging_configuration[:file], logging_configuration[:rotate])
    # ```
    #
    # @raise [ArgumentError] If the logging class does not exist.
    #
    # @param [String] The log.
    # @return [Hash] The logging configuration hash with the file & rotation configuration.
    def logging_configuration(log)
        raise Exception.new('You need to load the configuration before using it.') if @config.nil?

        # Capitalize the log if we're given a string that starts with a lowercase letter.
        class_name = log
        class_name = class_name.capitalize if class_name =~ /^[a-z]/

        logging_class = get_class(class_name)
        raise ArgumentError.new("Logging class does not exist: #{log}") if logging_class.nil?

        # If we don't have a configuration, just return the defaults.
        if @config['logs'].nil? || @config['logs'][log].nil?
            return {
                'file': logging_class::DEFAULT_LOGGING_LOCATION,
                'rotate': logging_class::DEFAULT_LOGGING_ROTATION,
            }
        end

        log_file_location = @config['logs'][log]['file']
        log_file_rotation ||= logging_class::DEFAULT_LOGGING_LOCATION

        log_file_rotation = @config['logs'][log]['rotate']
        log_file_rotation ||= logging_class::DEFAULT_LOGGING_ROTATION

        return {
            'file': log_file_location,
            'rotate': log_file_rotation,
        }
    end

    # Returns the Slack URL from the configuration.
    #
    # @return [String] The Slack URL.
    def slack_url
        raise Exception.new('You need to load the configuration before using it.') if @config.nil?

        return @config[SLACK_URL_KEY]
    end

    private

        # Given a class name, gets the class if it exists.
        #
        # @param class_name [String] The class name.
        # @return [Class, nil] The class or nil.
        def get_class(class_name)
            klass = Module.const_get(class_name)
            return nil unless klass.is_a?(Class)
            return klass
        rescue NameError
            return nil
        end
end
