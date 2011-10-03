require 'rubygems'
require 'json'
require 'date'
require 'pp'
require 'messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusRubyApi::Client.new(api_key)

# send an email with the headers and params set above
required_headers = {:fromEmail => "bob@example.com", :customHeaders => {"sender"=>"bob@example.com","reply-to"=>"bob@example.com"}}
required_params = {:toEmail => "apitest1@messagebus.com", :subject => "subject text", :htmlBody => "<p>html body</p>", :plaintextBody => "plaintext body"}
begin
  client.send_common_info=required_headers
  client.add_message(required_params)
  client.flush
  if client.send_return_status[:statusMessage] == "OK"
    status = client.send_return_status
    puts "Successfully sent #{status[:successCount]} messages."
    puts "Message ID: #{status[:results][0][:messageId]}"
  end
rescue Exception => e
  puts "Error occurred while sending messages."
  puts e.message
end

