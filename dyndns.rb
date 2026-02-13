require 'aws-sdk-route53'
require 'http'

class DynDNS
  IP_SERVICES = [
    'https://ifconfig.me/ip',
    'https://api.ipify.org',
    'https://icanhazip.com',
  ].freeze

  IPV4_REGEX = /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/

  def initialize(route53_client: Aws::Route53::Client.new, ip_fetcher: nil)
    @route53 = route53_client
    @ip_fetcher = ip_fetcher || method(:fetch_public_ip)
  end

  def update(domains_env)
    ip = @ip_fetcher.call
    domains = parse_domains(domains_env)

    domains.each do |name, zone_id|
      puts "[BEGIN] Updating #{name} on #{zone_id} to #{ip}"
      @route53.change_resource_record_sets(
        hosted_zone_id: zone_id,
        change_batch: {
          changes: [
            {
              action: 'UPSERT',
              resource_record_set: {
                name: name,
                type: 'A',
                ttl: 500,
                resource_records: [{ value: ip }]
              }
            }
          ]
        }
      )
      puts "[END] Updating #{name} on #{zone_id}"
    end
  end

  private

  def fetch_public_ip
    errors = []
    IP_SERVICES.each do |url|
      ip = HTTP.timeout(5).get(url).body.to_s.strip
      return ip if ip.match?(IPV4_REGEX)
      errors << "#{url} returned invalid IP: #{ip.inspect}"
    rescue => e
      errors << "#{url} failed: #{e.message}"
    end
    raise "Could not determine public IP from any service:\n  #{errors.join("\n  ")}"
  end

  def parse_domains(raw)
    raw.lines.map(&:strip).to_h do |line|
      name, id = line.split('=')
      [name, id]
    end
  end
end

