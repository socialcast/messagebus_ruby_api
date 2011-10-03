require 'rubygems'
require 'json'
require 'date'
require 'pp'
require 'messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
api_key="A7A98AAB0E95808842A3A0404364A352"
client= MessagebusRubyApi::Client.new(api_key)
client.basic_auth_credentials=({:user => "demo", :password => "319MBPmi"})

begin
  response = client.get_error_report

  if response[:statusMessage] == "OK"
    puts "Error Report has #{response[:results].length} entries."
  end
rescue Exception => e
  puts "Error occurred while getting error report."
  puts e.message
end

