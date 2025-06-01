require_relative 'dyndns'

dyndns = DynDNS.new

domains_env = ENV['DOMAINS']
if domains_env.nil? || domains_env.empty?
  warn "DOMAINS environment variable is missing or empty"
  exit 1
end

dyndns.update(domains_env)
