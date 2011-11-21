dir = File.dirname(__FILE__)
require "#{dir}/../spec_helper"

describe MessagebusApi::Messagebus do
  attr_reader :client, :api_key, :required_params

  def default_message_params
    { :toEmail => 'apitest1@messagebus.com',
      :toName => 'EmailUser',
      :fromEmail => 'api@messagebus.com',
      :fromName => 'API',
      :subject => 'Unit Test Message',
      :customHeaders => ["sender"=>"apitest1@messagebus.com"],
      :plaintextBody => 'This message is only a test sent by the Ruby MessageBus client library.',
      :htmlBody => "<html><body>This message is only a test sent by the Ruby MessageBus client library.</body></html>",
      :tags => ['RUBY', 'Unit Test Ruby']
    }
  end

  def default_template_message_params
    { "toEmail" => 'apitest1@messagebus.com',
      "toName" => 'John Smith',
      "templateKey" => '66f6181bcb4cff4cd38fbc804a036db6',
      "customHeaders" => ["reply-to"=>"apitest1@messagebus.com"],
      "mergeFields" => ["%NAME%" => "John"]
    }
  end

  def create_success_result(num_result)
    list=[]
    num_result.times do
      list << @success_message
    end
    success_result = {
      "statusMessage" => "OK",
      "successCount" => num_result,
      "failureCount" => 0,
      "results" => list
    }
    success_result
  end

  def create_results_array
    results = {
        "statusMessage" => "OK",
        "results" => []
    }
    results
  end

  before do
    FakeWeb.allow_net_connect = false

    @api_key = "7215ee9c7d9dc229d2921a40e899ec5f"
    @client = MessagebusApi::Messagebus.new(@api_key)
    @success_message={
      "status" => 200,
      "messageId" => "abcdefghijklmnopqrstuvwxyz012345"
    }
    @simple_success_result = create_success_result(1)
  end

  describe "messagebus object set up correctly" do
    it "has correct headers set for api calls" do
      client = MessagebusApi::Messagebus.new(@api_key)

    end
  end

  describe "#add_message" do
    it "buffered send that adds to empty buffer" do
      client.add_message(default_message_params)
      client.flushed?.should be_false
    end

    it "buffered send that adds to empty buffer and sends with flush_buffer flag" do
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v3/emails/send", :body => create_success_result(client.message_buffer_size).to_json)
      client.add_message(default_message_params, true)
      client.flushed?.should be_true
    end

    it "should have user-agent and x-messagebus-key set in request headers" do
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v3/emails/send", :body => create_success_result(client.message_buffer_size).to_json)
      client.add_message(default_message_params, true)
      client.flushed?.should be_true

      FakeWeb.last_request.get_fields("X-MessageBus-Key").should_not be_nil
      FakeWeb.last_request.get_fields("User-Agent").should_not be_nil
      FakeWeb.last_request.get_fields("Content-Type").should_not be_nil
    end

    it "buffered send that adds to a buffer and auto-flushes" do
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v3/emails/send", :body => create_success_result(client.message_buffer_size).to_json)
      client.send_common_info=@common_options
      (client.message_buffer_size-1).times do |idx|
        client.add_message(default_message_params)
        client.flushed?.should be_false
      end
      client.add_message(default_message_params)
      client.flushed?.should be_true
      client.results[:results].size.should == client.message_buffer_size
    end
  end

  describe "#flush" do
    it "flush called on empty buffer" do
      client.flush
      client.flushed?.should be_false
    end

    it "flush called on partially filled buffer" do
      message_count = 9
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v3/emails/send", :body => create_success_result(message_count).to_json)
      (message_count).times do |idx|
        client.add_message(default_message_params)
        client.flushed?.should be_false
      end
      client.flush
      client.flushed?.should be_true
      client.results[:results].size.should == message_count
    end
  end

  describe "#message_buffer_size=" do
    it "can set the buffer size" do
      client.message_buffer_size=(10)
      client.message_buffer_size.should == 10
    end

    it "cannot set an invalid buffer size" do
      default_buffer_size = 20
      client.message_buffer_size=(-1)
      client.message_buffer_size.should == default_buffer_size

      client.message_buffer_size=(0)
      client.message_buffer_size.should == default_buffer_size

      client.message_buffer_size=(101)
      client.message_buffer_size.should == default_buffer_size

      client.message_buffer_size=(1)
      client.message_buffer_size.should == 1

      client.message_buffer_size=(100)
      client.message_buffer_size.should == 100
    end
  end

  describe "#bulk_send" do

    before do
      @common_options={:fromEmail => "bob@example.com", :customHeaders => {"reply-to"=>"no-reply@example.com"}}
    end

    #xit "send a several item buffer" do
    #  buffer=[required_params, required_params]
    #  @success_result2 = {
    #    "statusMessage" => "OK",
    #    "successCount" => 2,
    #    "failureCount" => 0,
    #    "results" => [
    #      {
    #        "status" => 200,
    #        "messageId" => "e460d7f0-908e-012e-80b4-58b035f30fd1"
    #      },
    #      {
    #        "status" => 200,
    #        "messageId" => "e460d7f0-908e-012e-80b4-58b035f30fd2"
    #      }
    #    ]}
    #  FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v3/emails/send", :body => @success_result2.to_json)
    #  expect do
    #    client.add_message(buffer)
    #    response = client.buffered_send(buffer, @common_options)
    #    FakeWeb.last_request.body.should =~ /json=/
    #    response[:successCount].should == 2
    #  end.should_not raise_error
    #end
  end

  describe "#delivery_errors" do
    it "request delivery errors list" do

      start_date_str="2011-01-01"
      end_date_str="2011-01-02"

      @success_result={
        :reportSize=>2,
        :results=>[
          {:date => start_date_str, :address => "someguy@example.com", :errorCode => "4.2.1"},
          {:date => end_date_str, :address => "someguy@example.com", :errorCode => "5.0.0"}
        ]
      }

      #FakeWeb.register_uri(:get, "https://api.messagebus.com/api/v3/emails/error_report?apiKey=#{@api_key}", :body => @success_result.to_json)
      FakeWeb.register_uri(:get, "https://api.messagebus.com/api/v3/delivery_errors?startDate=#{start_date_str}&endDate=#{end_date_str}", :body => @success_result.to_json)
      expect do
        response = client.delivery_errors(start_date_str, end_date_str)
        FakeWeb.last_request.body.should be_nil
        response.should == @success_result
      end.should_not raise_error
    end
  end

  describe "#get_unsubscribe_results" do
    it "request blocked emails list" do

      start_date_str="2011-01-01T04:30:00+00:00"
      end_date_str="2011-01-02T04:30:00+00:00"

      @success_result=[
        {:email=>"test1@example.com", :message_send_time=>"2011-01-01T03:02:00", :unsubscribe_time=>"2011-01-02T04:32:00", :message_id=>"testmessageid1"},
        {:email=>"test2@example.com", :message_send_time=>"2011-01-01T02:02:00", :unsubscribe_time=>"2011-01-02T02:32:00", :message_id=>"testmessageid2"}
      ]
      expected_request="https://api.messagebus.com/api/v3/unsubscribes?startDate=#{URI.escape(start_date_str)}&endDate=#{URI.escape(end_date_str)}"

      FakeWeb.register_uri(:get, expected_request, :body => @success_result.to_json)
      expect do
        response = client.unsubscribes(start_date_str, end_date_str)
        FakeWeb.last_request.body.should be_nil
        response.should == @success_result
      end.should_not raise_error
    end
  end

  describe "#remove_mailing_list_entry" do
    it "remove from mailing list" do
      mailing_list_key="test_key"
      to_email="test@example.com"

      expected_request="https://api.messagebus.com/api/v3/mailing_list/test_key/entry/test@example.com"

      FakeWeb.register_uri(:delete, expected_request, :body => {"statusMessage" => "OK"}.to_json)
      expect do
        response = client.delete_mailing_list_entry(mailing_list_key, to_email)
        FakeWeb.last_request.body.should be_nil
        response.should == {:statusMessage => "OK"}
        FakeWeb.last_request.body
      end.should_not raise_error

    end
  end

  describe "#add_mailing_list_entry" do
    it "add to mailing list" do
      mailing_list_key="test_key"
      merge_fields={"%EMAIL%"=>"test@example.com", "%PARAM1%"=>"test value"}
      expected_request="https://api.messagebus.com/api/v3/mailing_list/test_key/entries"

      FakeWeb.register_uri(:post, expected_request, :body => {"statusMessage" => "OK"}.to_json)
      expect do
        response = client.add_mailing_list_entry(mailing_list_key, merge_fields)
        FakeWeb.last_request.body.should =~ /mergeField/
        response.should == {:statusMessage => "OK"}
      end.should_not raise_error

    end
  end

  describe "#mailing_lists" do
    it "get mailing lists" do
      expected_request="https://api.messagebus.com/api/v3/mailing_lists"

      FakeWeb.register_uri(:get, expected_request, :body => create_results_array.to_json)
      expect do
        response = client.mailing_lists
        response.should == {:statusMessage => "OK", :results => []}
      end.should_not raise_error
    end
  end

end

