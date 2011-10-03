require 'rubygems'
require 'json'
require 'date'
require 'pp'
require 'messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusRubyApi::Client.new(api_key)

begin
  start_date_str="2011-01-01"
  end_date_str="2011-01-02"
  response = client.get_unsubscribe_results(start_date_str, end_date_str)

  if response[:statusMessage] == "OK"
    puts "Blocked emails  has #{response[:results].length} entries."
  end
rescue Exception => e
  puts "Error occurred while getting blocked emails report."
  puts e.message
end
