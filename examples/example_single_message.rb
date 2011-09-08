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
required_params = {:toEmail => "jane@example.com", :subject => "subject text", :htmlBody => "<p>html body</p>", :plaintextBody => "plaintext body"}
client.send_common_info=required_headers
client.add_message(required_params)
client.flush
# print return_status
puts client.send_return_status



