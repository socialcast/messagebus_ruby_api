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
    @required_params = {:toEmail => "bob@example.com", :plaintextBody => "a nice ocean", :subject => "test subject"}
    @success_message={
      "status" => 200,
      "messageId" => "e460d7f0-908e-012e-80b4-58b035f30fd1"
    }
    @simple_success_result = create_success_result(1)
  end

  describe "#bulk_send" do

    before do
      @common_options={:fromEmail => "bob@example.com", :customHeaders => {"customfield1"=>"custom value 1", "customfield2"=>"custom value 2"}}
    end

    describe "#add_message" do
      it "buffered send that adds to empty buffer" do
        client.send_common_info=@common_options
        client.email_buffer.size.should == 0
        client.add_message(required_params)
        client.email_buffer.size.should == 1
      end

      it "buffered send that adds to a buffer and auto-flushes" do
        FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send", :body => create_success_result(client.email_buffer_size).to_json)
        client.send_common_info=@common_options
        client.send_return_status[:results].size.should == 0
        (client.email_buffer_size-1).times do |idx|
          client.add_message(required_params).should == idx+1
          client.send_return_status[:results].size.should == 0
        end
        client.add_message(required_params).should == 0
        client.send_return_status[:results].size.should == client.email_buffer_size
      end
    end

    describe "#flush" do
      it "flush called on empty buffer" do
        client.send_common_info=@common_options
        client.send_return_status[:results].size.should == 0
        client.flush
        client.send_return_status[:results].size.should == 0
      end
      it "flush called on filled buffer" do
        FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send", :body => create_success_result(10).to_json)
        client.send_common_info=@common_options
        10.times do
          client.add_message(required_params)
        end
        client.flush
        client.send_return_status[:results].size.should == 10
      end
    end

    it "send an empty buffer" do
      expect do
        response = client.buffered_send([], @common_options)
        response[:successCount].should == 0
      end.should_not raise_error
    end

    it "send a single item buffer" do
      buffer=[required_params]
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send", :body => @simple_success_result.to_json)
      #expect do
      response = client.buffered_send(buffer, @common_options)
      FakeWeb.last_request.body.should =~ /json=/
      response[:successCount].should == 1
      #end.should_not raise_error
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
      FakeWeb.register_uri(:post, "https://api.messagebus.com/api/v2/emails/send", :body => @success_result2.to_json)
      expect do
        response = client.buffered_send(buffer, @common_options)
        FakeWeb.last_request.body.should =~ /json=/
        response[:successCount].should == 2
      end.should_not raise_error
    end
  end

  describe "#error_report" do

    it "request error report" do
      @success_result={
        :reportSize=>2,
        :results=>
        [
        {:date => (Time.now-(60*60*24)).utc.to_datetime.rfc3339, :address => "someguy@example.com", :errorCode => "4.2.1"},
        {:date => Time.now.utc.to_datetime.rfc3339, :address => "someguy@example.com", :errorCode => "5.0.0"}
        ]
      }

      FakeWeb.register_uri(:get, "https://api.messagebus.com/api/v2/emails/error_report?apiKey=#{@api_key}", :body => @success_result.to_json)
      expect do
        response = client.error_report
        FakeWeb.last_request.body.should be_nil
        response.should == @success_result
      end.should_not raise_error
    end
  end

  describe "#blocked_emails" do

    it "request blocked emails list" do

      start_date_str="2011-01-01T04:30:00+00:00"
      end_date_str="2011-01-02T04:30:00+00:00"
      start_date=DateTime.parse(start_date_str)
      end_date=DateTime.parse(end_date_str)
      @success_result=[
        {:email=>"test1@example.com", :message_send_time=>"2011-01-01T03:02:00", :unsubscribe_time=>"2011-01-02T04:32:00", :message_id=>"testmessageid1"},
        {:email=>"test2@example.com", :message_send_time=>"2011-01-01T02:02:00", :unsubscribe_time=>"2011-01-02T02:32:00", :message_id=>"testmessageid2"}
      ]
      expected_request="https://api.messagebus.com/api/v2/blocked_emails?apiKey=#{@api_key}&startDate=#{URI.escape(start_date_str)}&endDate=#{URI.escape(end_date_str)}"

      FakeWeb.register_uri(:get, expected_request, :body => @success_result.to_json)
      expect do
        response = client.blocked_emails(start_date, end_date)
        FakeWeb.last_request.body.should be_nil
        response.should == @success_result
      end.should_not raise_error
    end
  end

  describe "#remove_from_mailing_list" do

    it "remove from mailing list" do
      mailing_list_key="test_key"
      to_email="test@example.com"

      expected_request="https://api.messagebus.com/api/v2/mailing_list_entry/destroy"

      FakeWeb.register_uri(:delete, expected_request, :body => {"statusMessage" => "OK"}.to_json)
      expect do
        response = client.remove_from_mailing_list(mailing_list_key, to_email)
        FakeWeb.last_request.body.should =~ /json=/
        response.should == {:statusMessage => "OK"}
        FakeWeb.last_request.body
      end.should_not raise_error

    end
  end

  describe "#add_to_mailing_list" do

    it "add to mailing list" do
      mailing_list_key="test_key"
      merge_fields={"%EMAIL%"=>"a@example.com", "%PARAM1%"=>"test value"}
      expected_request="https://api.messagebus.com/api/v2/mailing_list_entry/add_entry"

      FakeWeb.register_uri(:post, expected_request, :body => {"statusMessage" => "OK"}.to_json)
      expect do
        response = client.add_to_mailing_list(mailing_list_key, merge_fields)
        FakeWeb.last_request.body.should =~ /json=/
        response.should == {:statusMessage => "OK"}
      end.should_not raise_error

    end
  end

end

