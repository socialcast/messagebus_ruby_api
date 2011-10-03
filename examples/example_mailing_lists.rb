require 'rubygems'
require 'json'
require 'date'
require 'pp'
require 'messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusRubyApi::Client.new(api_key)

begin
  response = client.get_mailing_lists

  if response[:statusMessage] == "OK"
    response[:results].each do |item|
      puts "Mailing list: #{item[:name]} with key #{item[:key]}"
    end
  end
rescue Exception => e
  puts "Error occurred while getting mailing lists."
  puts e.message
end

