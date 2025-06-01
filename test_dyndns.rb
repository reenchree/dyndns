require 'minitest/autorun'
require 'mocha/minitest'
require_relative 'dyndns'

class TestDynDNS < Minitest::Test
  def setup
    @mock_r53 = mock('aws_route53_client')
    @fake_ip = "8.8.8.8"
    @domains_env = <<~DOMAINS
      test.example.com=Z123456EXAMPLE
      foo.bar=Z654321EXAMPLE
    DOMAINS

    @dyndns = DynDNS.new(
      route53_client: @mock_r53,
      ip_fetcher: -> { @fake_ip }
    )
  end

  def test_updates_all_domains
    @mock_r53.expects(:change_resource_record_sets).with do |args|
      args[:hosted_zone_id] == "Z123456EXAMPLE" &&
      args[:change_batch][:changes] == [{
        action: 'UPSERT',
        resource_record_set: {
          name: "test.example.com",
          type: "A",
          ttl: 500,
          resource_records: [{ value: @fake_ip }]
        }
      }]
    end

    @mock_r53.expects(:change_resource_record_sets).with do |args|
      args[:hosted_zone_id] == "Z654321EXAMPLE" &&
      args[:change_batch][:changes] == [{
        action: 'UPSERT',
        resource_record_set: {
          name: "foo.bar",
          type: "A",
          ttl: 500,
          resource_records: [{ value: @fake_ip }]
        }
      }]
    end

    @dyndns.update(@domains_env)
  end
end
