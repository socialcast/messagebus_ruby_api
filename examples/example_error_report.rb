require 'rubygems'
require 'json'
require 'date'
require 'pp'
require 'messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusRubyApi::Client.new(api_key)

begin
  response = client.get_error_report

  if response[:statusMessage] == "OK"
    puts "Error Report has #{response[:results].length} entries."
  end
rescue Exception => e
  puts "Error occurred while getting error report."
  puts e.message
end

