require 'rubygems'
require 'json'
require 'date'
require 'pp'
require 'messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusRubyApi::Client.new(api_key)

# send an email with the headers and params set above
mailing_list_key="YOUR_MAILING_LIST_KEY_GOES_HERE"
email_address = "some.one@example.com"

begin
  response=client.remove_mailing_list_entry(mailing_list_key, email_address)
  if response[:statusMessage] == "OK"
    puts "Mailing list entry removed for #{email_address}."
  end
rescue Exception => e
  puts "Error occurred while deleting entry."
  puts e.message
end
