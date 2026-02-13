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

  def test_fetch_public_ip_uses_first_valid_response
    dyndns = DynDNS.new(route53_client: @mock_r53)

    stub_request = stub('response', body: stub(to_s: "1.2.3.4"))
    http_stub = stub('http')
    http_stub.stubs(:get).with('https://ifconfig.me/ip').returns(stub_request)
    HTTP.stubs(:timeout).with(5).returns(http_stub)

    @mock_r53.stubs(:change_resource_record_sets)
    dyndns.update("test.example.com=Z123456EXAMPLE\n")
  end

  def test_fetch_public_ip_falls_back_on_invalid_response
    dyndns = DynDNS.new(route53_client: @mock_r53)

    bad_response = stub('bad_response', body: stub(to_s: "upstream connect error"))
    good_response = stub('good_response', body: stub(to_s: "1.2.3.4"))
    http_stub = stub('http')
    http_stub.stubs(:get).with('https://ifconfig.me/ip').returns(bad_response)
    http_stub.stubs(:get).with('https://api.ipify.org').returns(good_response)
    HTTP.stubs(:timeout).with(5).returns(http_stub)

    @mock_r53.expects(:change_resource_record_sets).with do |args|
      args[:change_batch][:changes][0][:resource_record_set][:resource_records] == [{ value: "1.2.3.4" }]
    end

    dyndns.update("test.example.com=Z123456EXAMPLE\n")
  end

  def test_fetch_public_ip_falls_back_on_exception
    dyndns = DynDNS.new(route53_client: @mock_r53)

    good_response = stub('good_response', body: stub(to_s: "1.2.3.4"))
    http_stub = stub('http')
    http_stub.stubs(:get).with('https://ifconfig.me/ip').raises(HTTP::TimeoutError, "timed out")
    http_stub.stubs(:get).with('https://api.ipify.org').returns(good_response)
    HTTP.stubs(:timeout).with(5).returns(http_stub)

    @mock_r53.expects(:change_resource_record_sets)
    dyndns.update("test.example.com=Z123456EXAMPLE\n")
  end

  def test_fetch_public_ip_raises_when_all_services_fail
    dyndns = DynDNS.new(route53_client: @mock_r53)

    bad_response = stub('bad_response', body: stub(to_s: "not an ip"))
    http_stub = stub('http')
    http_stub.stubs(:get).returns(bad_response)
    HTTP.stubs(:timeout).with(5).returns(http_stub)

    assert_raises(RuntimeError) { dyndns.update("test.example.com=Z123456EXAMPLE\n") }
  end
end
