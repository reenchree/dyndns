# Ruby DynDNS Updater (Route 53)

This is a simple Dynamic DNS updater written in Ruby. It uses [AWS Route 53](https://aws.amazon.com/route53/) to update A records for one or more domains with your current public IP address.

It’s intended to be run periodically (e.g. as a cron job) on a machine with a dynamic IP, such as a home server.

## 📆 Requirements

* Ruby 3.x
* Bundler (`gem install bundler`)
* AWS credentials configured via environment variables, profile, or instance role
* Your domain(s) must be hosted in Route 53

## 🔧 Environment Variables

The script uses the following environment variables:

### `DOMAINS`

```
DOMAINS="example.com=Z123456ABCDEF
home.mydomain.net=Z987654ZYXWVU"
```

Each line maps a fully-qualified domain name to a Route 53 **hosted zone ID**, using `=` as the delimiter. Multiple domains are supported by separating entries with newlines (`\n` in environment files or heredocs).

### `TTL`

Specifies the TTL (Time to Live) in seconds for each DNS record. If not set, the default is `500`.

```
TTL=500
```

You can export these in your shell or store them in an `.env` file if using a task runner.

## 🚀 Running the Script

Install dependencies:

```bash
bundle install
```

Then run:

```bash
ruby dyndns.rb
```

Or add it to cron (every 5 minutes is a good default):

```cron
*/5 * * * * /usr/bin/env DOMAINS="$(cat /path/to/domains.env)" TTL=300 /usr/bin/ruby /path/to/dyndns.rb
```

## 🥪 Running Tests

```bash
bundle exec ruby test_dyndns.rb
```

Test dependencies (like `mocha` and `webmock`) are scoped to the `:test` group in the Gemfile.
