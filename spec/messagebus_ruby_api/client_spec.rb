dir = File.dirname(__FILE__)
require "#{dir}/../spec_helper"

describe MessagebusRubyApi::Client do
  attr_reader :client, :api_key, :required_params

  def create_success_result(num_result)
    list=[]
    num_result.times do
      list << @success_message
    end
    success_result = {
      "statusMessage" => "OK",
      "successCount" => 1,
      "failureCount" => 0,
      "results" => list
    }
    success_result
  end

  before do
    FakeWeb.allow_net_connect = false

    @api_key = "3"*32
    @client = MessagebusRubyApi::Client.new(api_key)
    @required_params = {:toEmail => "bob@example.com", :fromEmail => "alice@example.com", :plaintextBody => "a nice ocean", :subject => "test subject"}
    @success_message={
          "status" => 200,
          "messageId" => "e460d7f0-908e-012e-80b4-58b035f30fd1"
    }
    @simple_success_result = create_success_result(1)
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

  it "talks to the supplied endpoint url" do
    another_client = MessagebusRubyApi::Client.new(api_key, "http://localhost:8080/v1")
    another_client.endpoint_url.host.should =~ /localhost/
  end

  describe "required parameters" do
    it "works when the minimum params are sent" do
      FakeWeb.register_uri(:post, api_url, :body => @simple_success_result.to_json)
      response = nil
      expect do
        response = client.send_email(required_params)
      end.should_not raise_error
      response[:successCount].should == 1
    end

    it "works when an html body is supplied with no plaintext_body" do
      params = required_params.without(:plaintextBody).merge(:htmlBody => '<html>This is a test email</html>')
      FakeWeb.register_uri(:post, api_url, :body => @simple_success_result.to_json)
      response = nil
      expect do
        response = client.send_email(params)
      end.should_not raise_error
      response[:successCount].should == 1
    end

    it "raises errors when missing to_email param" do
      api_response = "missing or malformed parameter toEmail"
      expect_api_parameter_errors(required_params.without(:toEmail), api_response, "toEmail")
    end

    it "raises errors when missing from_email param" do
      api_response = "missing or malformed parameter fromEmail"
      expect_api_parameter_errors(required_params.without(:fromEmail), api_response, "fromEmail")
    end

    it "raises errors when missing subject param" do
      api_response = "missing or malformed parameter subject"
      expect_api_parameter_errors(required_params.without(:subject), api_response, "subject")
    end

    it "raises errors when missing plaintext body param" do
      api_response = "missing or malformed parameter plaintextBody or htmlBody"
      expect_api_parameter_errors(required_params.without(:plaintextBody), api_response, "plaintextBody or htmlBody")
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

  describe "server errors" do
    it "raises an error with the error status received by the server" do
      error_response_body = failure_result("Some meaningful remote error").to_json
      FakeWeb.register_uri(:post, api_url, status: [500, ""], :body => error_response_body)
      expect do
        client.send_email(required_params)
      end.should raise_error(MessagebusRubyApi::RemoteServerError, "Remote Server Returned: 500.  Some meaningful remote error")
    end

    it "populates the error with a result containing the hash of server responses" do
      error_response_body = failure_result("Some meaningful remote error").to_json
      FakeWeb.register_uri(:post, api_url, status: [400, ""], :body => error_response_body)
      begin
        client.send_email(required_params)
      rescue MessagebusRubyApi::RemoteServerError => e
        e.result[:statusMessage].should == "Some meaningful remote error"
      end
    end

    it "raises an error if the remote server returns a status other than 200 OK" do
      FakeWeb.register_uri(:post, api_url, :status => [404, "Not Found"], :body => "")
      expect do
        client.send_email(required_params)
      end.should raise_error(MessagebusRubyApi::RemoteServerError, "Remote Server Returned: 404")
    end

    it "raises an error when the server does not return a json string" do
      FakeWeb.register_uri(:post, api_url, :body => "i am not a json string")
      expect do
        client.send_email(required_params)
      end.should raise_error(MessagebusRubyApi::RemoteServerError, "Remote server returned unrecognized response: 706: unexpected token at 'i am not a json string'")
    end
  end

  describe "#basic_auth_credentials=" do
    it "uses basic auth with the supplied credentials" do
      client.basic_auth_credentials = {:user => "user", :password => "pass"}
      FakeWeb.register_uri(:post, api_url, :body => "Unauthorized", :status => ["401", "Unauthorized"])
      FakeWeb.register_uri(:post, "https://user:pass@api.messagebus.com/api/v2/emails/send", :body => @simple_success_result.to_json)
      expect do
        client.send_email(required_params)
      end.should_not raise_error
    end
  end


  describe "#bulk_send" do

    before do
      @common_options={:fromEmail => "bob@example.com"}
    end

    describe "#setup_connection" do
      it "setup a connection that wasnt taken down" do
        client.setup_connection(@common_options)
        expect do
          client.setup_connection(@common_options)
        end.should raise_error
      end
    end

    describe "#buffered_send" do
      it "buffered send that adds to empty buffer" do
        client.setup_connection(@common_options)
        client.buffer.size.should == 0
        client.buffered_send(required_params)
        client.buffer.size.should == 1
      end
      it "attempt to buffered send without a connection setup" do
        expect do
          client.buffered_send(required_params)
        end.should raise_error
      end
      it "buffered send that adds to a buffer and auto-flushes" do
                FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send_emails", :body => create_success_result(100).to_json)
        client.setup_connection(@common_options)
        client.status_from_last_flush.should be_nil
        #client.status_from_last_flush.results.size.should == 0
        99.times do |idx|
          client.buffered_send(required_params).should == idx+1
          client.status_from_last_flush.should be_nil
        end
        client.buffered_send(required_params).should == 0
        client.status_from_last_flush[:results].size.should == 100
      end
    end

    describe "#flush" do
      it "flush called on nonsetup connection" do
        expect do
          client.flush
        end.should raise_error
      end
      it "flush called on empty buffer" do
        client.setup_connection(@common_options)
        client.flush
        client.status_from_last_flush.should
      end
      it "flush called on filled buffer" do
        FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send_emails", :body => create_success_result(20).to_json)
        client.setup_connection(@common_options)
        20.times do
          client.buffered_send(required_params)
        end
        client.flush
        client.status_from_last_flush[:results].size.should == 20
      end
    end

    describe "#teardown_connection" do
      it "teardown called on nonsetup connection" do
        expect do
          client.teardown_connection
        end.should raise_error
      end
      it "teardown called on nonempty buffer" do
        client.setup_connection(@common_options)
        client.buffered_send(required_params)
        client.buffer.size.should == 1
        expect do
          client.teardown_connection
        end.should raise_error
      end
      it "teardown called with empty buffer because it wasnt used" do
        client.setup_connection(@common_options)
        client.teardown_connection
      end
      it "teardown called with empty buffer because it was flushed" do
        client.setup_connection(@common_options)
        client.buffered_send(required_params)
        client.buffer.size.should == 1
        client.flush
        client.teardown_connection
      end
    end

    it "send an empty buffer" do
      expect do
        response = client.bulk_send([], @common_options)
        response[:successCount].should == 0
      end.should_not raise_error
      #check no server calls were called
    end

    it "send a single item buffer" do
      buffer=[required_params]
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send_emails", :body => @simple_success_result.to_json)
      expect do
        response = client.bulk_send(buffer, @common_options)
        response[:successCount].should == 1
      end.should_not raise_error
    end

    it "send a several item buffer" do
      buffer=[required_params, required_params]
      @success_result2 = {
        "statusMessage" => "OK",
        "successCount" => 2,
        "failureCount" => 0,
        "results" => [
          {
            "status" => 200,
            "messageId" => "e460d7f0-908e-012e-80b4-58b035f30fd1"
          },
          {
            "status" => 200,
            "messageId" => "e460d7f0-908e-012e-80b4-58b035f30fd2"
          }
        ]}
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send_emails", :body => @success_result2.to_json)
      expect do
        response = client.bulk_send(buffer, @common_options)
        response[:successCount].should == 2
      end.should_not raise_error
    end
  end
end

def expect_api_success(params)
  FakeWeb.register_uri(:post, api_url, :body => @simple_success_result.to_json)
  expect do
    response = client.send_email(params)
    response[:statusMessage].should == "OK"
  end.should_not raise_error
end

def expect_api_parameter_errors(params, fake_response, expected_error_message="")
  FakeWeb.register_uri(:post, api_url,
                       :body => fake_response)
  expect do
    client.send_email(params)
  end.should raise_error(MessagebusRubyApi::APIParameterError, "missing or malformed parameter #{expected_error_message}")
end

def api_url
  "https://api.messagebus.com/api/v2/emails/send"
end

def failure_result(message)
  {"statusMessage" => message}
end

