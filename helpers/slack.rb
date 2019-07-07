# A lil' helper class for sending Slack messages to our Slack endpoint.
module Slack

    # The endpoint for sending messages to our Slack instance.
    # @return [String] Our Slack endpoint.
    URL = 'https://hooks.slack.com/services/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'

    # Constants for the various levels of Slack attachments.
    LEVEL_INFO = 'info'
    LEVEL_LOW = 'low'
    LEVEL_MEDIUM = 'medium'
    LEVEL_HIGH = 'high'

    # The different attachment colors for the Slack levels.
    # @return [Hash<String => String> The colors.
    LEVEL_COLORS = {
        LEVEL_INFO => '#6c757d',
        LEVEL_LOW => '#17a2b8',
        LEVEL_MEDIUM => '#ffc107',
        LEVEL_HIGH => '#dc3545',
    }

    # Sends a message to our Slack instance.
    #
    # @param message [String] The message to send.
    # @return [Boolean] Was the send successful?
    def self.send_message!(message)
        resp = HTTParty.post(Config.instance.slack_url,
            body: { text: message }.to_json,
            headers: { 'Content-Type': 'application/json' }
        )

        # Was the message send successful?
        return (resp.code === 200)
    end

    # Sends attachments to our Slack instance.
    #
    # @param attachments [Array, Hash] The attachment to send.
    # @return [Boolean] Was the send successful?
    def self.send_attachment!(attachments)
        # If given a single attachment (a Hash), turn it into an array.
        attachments = [attachments] if attachments.is_a?(Hash)

        resp = HTTParty.post(Config.instance.slack_url,
            body: { 'attachments': attachments }.to_json,
            headers: { 'Content-Type': 'application/json' }
        )

        # Was the message send successful?
        return (resp.code === 200)
    end

    # Formats a Slack attachment to send to our instance.
    #
    # @raise [ArgumentError] If the level is invalid.
    #
    # @param summary [String] The summary of the message.
    # @param fields [Array<Hashes>] The fields of the message.
    # @param level [String] The 'level' of the attachment (i.e. "high", "medium", "low")
    # @return [Hash] The attachment.
    def self.format_attachment(summary, fields, level = 'low')
        raise ArgumentError.new('Invalid level') if LEVEL_COLORS[level].nil?

        return {
            'fallback': summary,
            'color': LEVEL_COLORS[level],
            'pretext': summary,
            'fields': fields,
            'footer': 'bug bounty in a box',
            'footer_icon': 'https://media.giphy.com/media/9WC8WTZsFxkRi/giphy.gif',
        }
    end
end
