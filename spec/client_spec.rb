require 'rubygems'
require 'fakeweb'
require 'cgi'

require "messagebus_ruby_api"

describe MessagebusRubyApi::Client do
  attr_reader :client, :api_key
  before do
    FakeWeb.allow_net_connect = false

    @api_key = "3"*32
    @client = MessagebusRubyApi::Client.new(api_key)
  end

  it "requires an api key" do
    expect do
      MessagebusRubyApi::Client.new("foo")
    end.should raise_error(MessagebusRubyApi::BadAPIKeyError)
  end

  it "knows its API key" do
    client.api_key.should == api_key
  end

  it "works when the minimum params are sent" do
    params = {:to_email => "bob@example.com", :body => "a nice moon", :from_email => "alex@example.com", :subject => "test subject"}
    url_params = client.to_param(params)
    FakeWeb.register_uri(:post, api_url_from_params(url_params), :body => "OK: OK")
    expect do
      client.send_email(params)
    end.should_not raise_error
  end

  it "raises errors when missing to_email param" do
    params = {:body => "a nice moon", :from_email => "alex@example.com", :subject => "test subject"}
    api_response = "ERR :Missing required paramater toEmail"
    expect_api_errors(params, api_response)
  end

  it "raises errors when missing body param" do
    params = {:to_email => "bob@example.com", :from_email => "alex@example.com", :subject => "test subject"}
    api_response = "ERR:Missing required paramater body"
    expect_api_errors(params, api_response)
  end

  it "raises errors when missing from_email param" do
    params = {:to_email => "bob@example.com", :body => "a nice ocean", :subject => "test subject"}
    api_response = "ERR:Missing required paramater toEmail"
    expect_api_errors(params, api_response)
  end

end

def expect_api_errors(params, fake_response)
  url_params = client.to_param(params)
  FakeWeb.register_uri(:post, api_url_from_params(url_params),
                       :body => fake_response)
  expect do
    client.send_email(params)
  end.should raise_error(MessagebusRubyApi::APIParameterError)
end

def api_url_from_params(url_params)
  "https://api.messagebus.com/send&operation=send&#{url_params}"
end
