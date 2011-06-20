dir = File.dirname(__FILE__)
require "#{dir}/../spec_helper"

describe MessagebusRubyApi::Client do
  attr_reader :client, :api_key, :required_params
  before do
    FakeWeb.allow_net_connect = false

    @api_key = "3"*32
    @client = MessagebusRubyApi::Client.new(api_key)
    @required_params = {:toEmail => "bob@example.com", :fromEmail => "alice@example.com", :plaintextBody => "a nice ocean", :subject => "test subject"}
  end

  it "requires an api key" do
    expect do
      MessagebusRubyApi::Client.new("3"*32)
    end.should_not raise_error(MessagebusRubyApi::BadAPIKeyError)

    expect do
      MessagebusRubyApi::Client.new("foo")
    end.should raise_error(MessagebusRubyApi::BadAPIKeyError)
  end

  it "knows its API key" do
    client.api_key.should == api_key
  end

  it "defaults the endpoint URL if one is not supplied" do
    @client.endpoint_url.host.should =~ /api\.messagebus\.com/
  end

  it "has the version number in the default endpoint url" do
    @client.endpoint_url.to_s.should =~ /v1/
  end

  it "talks to the supplied endpoint url" do
    another_client = MessagebusRubyApi::Client.new(api_key, "http://localhost:8080/v1")
    another_client.endpoint_url.host.should =~ /localhost/
  end

  describe "required parameters" do
    it "works when the minimum params are sent" do
      url_params = client.to_param(required_params)
      FakeWeb.register_uri(:post, api_url_from_params(url_params), :body => "OK:OK")
      expect do
        client.send_email(required_params)
      end.should_not raise_error
    end

    it "works when an html body is supplied with no plaintext_body" do
      url_params = client.to_param(required_params.without(:plaintextBody).merge(:htmlBody => '<html>This is a test email</html>'))
      FakeWeb.register_uri(:post, api_url_from_params(url_params), :body => "OK:OK")
      expect do
        client.send_email(required_params)
      end.should_not raise_error
    end

    it "raises errors when missing to_email param" do
      api_response = "ERR :Missing required paramater toEmail"
      expect_api_errors(required_params.without(:toEmail), api_response, "toEmail")
    end

    it "raises errors when missing from_email param" do
      api_response = "ERR:Missing required paramater fromEmail"
      expect_api_errors(required_params.without(:fromEmail), api_response, "fromEmail")
    end

    it "raises errors when missing subject param" do
      api_response = "ERR:Missing required paramater subject"
      expect_api_errors(required_params.without(:subject), api_response, "subject")
    end

    it "raises errors when missing both body params" do
      api_response = "ERR:Missing required paramater body"
      expect_api_errors(required_params.without(:plaintextBody), api_response, "plaintextBody or htmlBody")
    end
  end

  describe "optional parameters" do
    it "allows to_name" do
      expect_api_success(required_params.merge(:toName => "Chuck Norris"))
    end

    it "allows from_name" do
      expect_api_success(required_params.merge(:fromName => "Sally Norris"))
    end

    it "allows tag" do
      expect_api_success(required_params.merge(:tag => "weekly"))
    end

    it "allows priority with values 1 through 5" do
      expect_api_success(required_params.merge(:priority => 1))
      expect_api_success(required_params.merge(:priority => 2))
      expect_api_success(required_params.merge(:priority => 3))
      expect_api_success(required_params.merge(:priority => 4))
      expect_api_success(required_params.merge(:priority => 5))

      expect do
        client.send_email(required_params.merge(:priority => "foo"))
      end.should raise_error(MessagebusRubyApi::APIParameterError)

      expect do
        client.send_email(required_params.merge(:priority => 0))
      end.should raise_error(MessagebusRubyApi::APIParameterError)

      expect do
        client.send_email(required_params.merge(:priority => 6))
      end.should raise_error(MessagebusRubyApi::APIParameterError)
    end

    it "allows reply_to" do
      expect_api_success(required_params.merge(:replyTo => "obiwan@example.com"))
    end

    it "allows unsubscribe_email" do
      expect_api_success(required_params.merge(:unsubscribeEmail => "unsubscribe@aol.com"))
    end

    it "allows unsubscribe_url" do
      expect_api_success(required_params.merge(:unsubscribeUrl => "http://foobar.com/unsubscribe"))
    end
  end

  describe "#to_param" do
    it "converts to param names and sorts them" do
      client.to_param({:toEmail => "bob@example.com", :fromEmail => "alex@example.com"}).should == "fromEmail=alex%40example.com&toEmail=bob%40example.com"
    end
  end

  describe "server errors" do
    it "raises an error with the error status received by the server" do
      url_params = client.to_param(required_params)
      error_response_body = "ERR:Some meaningful remote error"
      FakeWeb.register_uri(:post, api_url_from_params(url_params), status: [500, ""], :body => error_response_body)
      expect do
        client.send_email(required_params)
      end.should raise_error(MessagebusRubyApi::RemoteServerError, error_response_body)
    end

    it "raises an error if the remote server returns a status other than 200 OK" do
      url_params = client.to_param(required_params)
      FakeWeb.register_uri(:post, api_url_from_params(url_params), :status => [404, "Not Found"], :body => "")
      expect do
        client.send_email(required_params)
      end.should raise_error(MessagebusRubyApi::RemoteServerError, "ERR:Remote Server Returned: 404")
    end
  end

  describe "#basic_auth_credentials=" do
    it "uses basic auth with the supplied credentials" do
      client.basic_auth_credentials = {:user => "user", :password => "pass"}
      url_params = client.to_param(required_params)
      FakeWeb.register_uri(:post, api_url_from_params(url_params), :body => "Unauthorized", :status => ["401", "Unauthorized"])
      FakeWeb.register_uri(:post, "https://user:pass@api.messagebus.com/send?operation=sendEmail&apiKey=#{api_key}&#{url_params}", :body => "OK:OK")
      expect do
        client.send_email(required_params)
      end.should_not raise_error
    end
  end
end

def expect_api_success(params)
  expected_url = api_url_from_params(client.to_param(client.check_params(params.dup)))
  FakeWeb.register_uri(:post, expected_url, :body => "OK:OK")
  expect do
    response = client.send_email(params)
    response.body.should == "OK:OK"
  end.should_not raise_error
end

def expect_api_errors(params, fake_response, expected_error_message="")
  expected_params = client.to_param(params.dup)
  FakeWeb.register_uri(:post, api_url_from_params(expected_params),
                       :body => fake_response)
  expect do
    client.send_email(params)
  end.should raise_error(MessagebusRubyApi::APIParameterError, "missing or malformed parameter #{expected_error_message}")
end

def api_url_from_params(url_param_string)
  "https://api.messagebus.com/send?operation=sendEmail&apiKey=#{api_key}&#{url_param_string}"
end
