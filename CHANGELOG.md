# :rocket: CHANGELOG

## :soccer: Version 0.02

This second pre-release version contains some new routes:

1. `/payload`: Will return payload file of your type choice with a callback URL for your Bug Bounty in a Box instance.
    * Includes the following payloads:
        * XSS via JavaScript file
        * XSS via SVG
        * XXE via XML file
1. `/unauthorized`: Sends a 401 for non-OPTIONS & non-HEAD requests with a `Content-Type` header of your choice.

As well as the following changes:

1. Actually log/message the request URI. My b. If you were alreadying parsing request logs, you'll need to account for the fact that the request URI is now the first attribute in the log.
1. Remove some debug `p`s. Whoops.
1. Removed my hardcoded `hack @ ajoekerr` references. Now you won't see me & Juniper in Slack :sweat_smile:.
1. Some doc updates. Nothing huge.

## :dizzy_face: Version 0.01

Initial version! This version includes all of the features that are listed in [the README](https://github.com/andrewjkerr/bug-bounty-in-a-box/blob/5c22b1762b86c2c5d83b9d86024e4dfd52fc01e0/README.md#callback-server).
