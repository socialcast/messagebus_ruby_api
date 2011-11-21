require 'rubygems'
require 'json'
require 'date'
require 'pp'
require '../lib/messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"

client= MessagebusApi::Messagebus.new(api_key)

# retrieves message delivery errors
begin
  status = client.delivery_errors

  if status[:statusCode] == 200
    puts "Method returned successfully."
    status[:results].each do |result|
      puts "At #{result[:time]} mesage #{result[:messageId]} to #{status[:toEmail]} returned #{status[:DSNCode]}"
    end
  else
    puts "Problem in getting unsubscribe list. #{status[:statusCode]}-#{status[:statusMessage]}"
  end
rescue Exception => e
  puts "Error occurred while getting delivery errors report."
  puts e.message
end

