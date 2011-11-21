require 'rubygems'
require 'json'
require 'date'
require 'pp'
require '../lib/messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusApi::Messagebus.new(api_key)

begin
  start_date_str="2011-01-01"
  end_date_str="2011-01-02"
  status = client.unsubscribes(start_date_str, end_date_str)

  if status[:statusCode] == 200
    puts "Method returned successfully."
    status[:results].each do |result|
      puts "#{result[:toEmail]} unsubscribed at #{result[:time]}"
    end
  else
    puts "Problem in getting unsubscribe list. #{status[:statusCode]}-#{status[:statusMessage]}"
  end
rescue Exception => e
  puts "Error occurred while getting unsubscribes report."
  puts e.message
end
