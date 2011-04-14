require 'rubygems'
require 'fakeweb'

#dir = File.dirname(__FILE__)
require "spec_core_extensions"

require "messagebus_ruby_api"

describe MessagebusRubyApi::Client do
  attr_reader :client, :api_key, :required_params
  before do
    FakeWeb.allow_net_connect = false

    @api_key = "3"*32
    @client = MessagebusRubyApi::Client.new(api_key)
    @required_params = {:to_email => "bob@example.com", :from_email => "alice@example.com", :body => "a nice ocean", :subject => "test subject"}
  end

  it "requires an api key" do
    expect do
      MessagebusRubyApi::Client.new("foo")
    end.should raise_error(MessagebusRubyApi::BadAPIKeyError)
  end

  it "knows its API key" do
    client.api_key.should == api_key
  end

  it "should include the correct operation param" do

  end

  describe "required parameters" do
    it "works when the minimum params are sent" do
      url_params = client.to_param(required_params)
      FakeWeb.register_uri(:post, api_url_from_params(url_params), :body => "OK:OK")
      expect do
        client.send_email(required_params)
      end.should_not raise_error
    end

    it "raises errors when missing to_email param" do
      api_response = "ERR :Missing required paramater toEmail"
      expect_api_errors(required_params.without(:to_email), api_response, "to_email")
    end

    it "raises errors when missing from_email param" do
      api_response = "ERR:Missing required paramater fromEmail"
      expect_api_errors(required_params.without(:from_email), api_response, "from_email")
    end

    it "raises errors when missing subject param" do
      api_response = "ERR:Missing required paramater subject"
      expect_api_errors(required_params.without(:subject), api_response, "subject")
    end

    it "raises errors when missing body param" do
      api_response = "ERR:Missing required paramater body"
      expect_api_errors(required_params.without(:body), api_response, "body")
    end
  end

  describe "optional parameters" do
    it "allows to_name" do
      expect_api_success(required_params.merge(:to_name => "Chuck Norris"))
    end

    it "allows from_name" do
      expect_api_success(required_params.merge(:from_name => "Sally Norris"))
    end

    it "allows tag" do
      expect_api_success(required_params.merge(:tag => "weekly"))
    end

    describe "allows plain_text" do
      it "is happy with true or false as the value" do
        expect_api_success(required_params.merge(:plain_text => true))
      end

      it "raises a param error if anything besides true or false" do
        api_response = "doesn't matter"
        expect do
          expect_api_errors(required_params.without(:body), api_response, "body")
        end.should raise_error(APIParameterError.new("plain_text can only be true or false"))
      end
    end
  end

  describe "other params" do
    before do
      FakeWeb.allow_net_connect = true
    end

    after do
      FakeWeb.allow_net_connect = false
    end

    it "raises an error when missing implicit parameters" do
      params = {:to_email => "bob@example.com", :from_email => "sally@example.com", :body => "a nice ocean", :subject => "test subject"}
      api_response = "ERR: blam"
      url_params = client.to_param(params)
      full_url = "https://api.messagebus.com/send?#{url_params}"
      FakeWeb.register_uri(:post, full_url, :body => api_response)
      expect do
        client.send_email(params)
      end.should raise_error(MessagebusRubyApi::UnknownError)
    end
  end

  describe "#to_param" do
    it "camelizes param names and sorts them" do
      client.to_param({:to_email => "bob@example.com", :from_email => "alex@example.com"}).should == "fromEmail=alex%40example.com&toEmail=bob%40example.com"
    end
  end
end

def expect_api_success(params)
  expected_url = api_url_from_params(client.to_param(params))
  FakeWeb.register_uri(:post, expected_url, :body => "OK:OK")
  expect do
    response = client.send_email(params)
    response.body.should == "OK:OK"
  end.should_not raise_error
end

def expect_api_errors(params, fake_response, expected_error_message="")
  url_params = client.to_param(params)
  FakeWeb.register_uri(:post, api_url_from_params(url_params),
                       :body => fake_response)
  expect do
    client.send_email(params)
  end.should raise_error(MessagebusRubyApi::APIParameterError, "missing or malformed parameter #{expected_error_message}")
end

def api_url_from_params(url_param_string)
  "https://api.messagebus.com/send?operation=sendEmail&#{url_param_string}"
end
