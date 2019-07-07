require 'optparse'
require 'ruby-progressbar'
require 'uri'
require 'yaml'

# Parse the options to find the callback & the target.
options = {}
OptionParser.new do |opts|
    opts.banner = 'Usage: generate_payloads.rb [options]'

    opts.on('-c', '--callback BASE_CALLBACK_URL', 'The BASE_CALLBACK_URL for the payloads') do |c|
        options[:callback] = c
    end

    opts.on('-t', '--target TARGET', 'The TARGET for the payloads') do |t|
        options[:target] = t
    end

    opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
    end
end.parse!

# Check the required arguments.
if options[:callback].nil? || options[:target].nil?
    raise OptionParser::MissingArgument.new('Missing either the callback or target. Use --help for instructions.')
end

payload_files = Dir.glob('payloads/*.yml')

payload_files.each do|filename|
    # Load in the payload's YAML config.
    payload_yaml = YAML.load(File.read(filename))

    puts "Generating payloads for #{payload_yaml['name']}..."

    # Create a new progress bar.
    progress_bar = ProgressBar.create(
        title: "#{payload_yaml['name']}",
        total: payload_yaml['payloads'].length,
    )

    # Create a new output file.
    output = File.open(filename.gsub('.yml', '.txt'), 'w')

    # Go through each of the payload configs and convert them.
    payload_yaml['payloads'].each do |payload_config|
        # We support either a straight up payload or a payload config Hash.
        if payload_config.is_a?(Hash)
            payload = payload_config['payload']
            description = (payload_config['description'].nil? ? payload : payload_config['description'])
        else
            payload = payload_config
            description = payload
        end

        # Generate the query string to append to the callback URL.
        query_string = "payload=#{URI::encode(description)}&target=#{URI::encode(options[:target])}"
        callback_url_for_payload = "#{options[:callback]}?#{query_string}"

        # Add the generated payload to the output file.
        output << payload.gsub('CALLBACK_URL', callback_url_for_payload) + "\n"

        # Increment the progress bar!
        progress_bar.increment
    end

    output.close

    puts "Done!"
end
