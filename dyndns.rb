require 'aws-sdk-route53'
require 'http'

class DynDNS
  def initialize(route53_client: Aws::Route53::Client.new, ip_fetcher: nil)
    @route53 = route53_client
    @ip_fetcher = ip_fetcher || -> { HTTP.get('https://ifconfig.me/ip').body.to_s.strip }
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

  def parse_domains(raw)
    raw.lines.map(&:strip).to_h do |line|
      name, id = line.split('=')
      [name, id]
    end
  end
end

