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
merge_fields={"%EMAIL%"=>email_address}

begin
  response=client.add_mailing_list_entry(mailing_list_key, merge_fields)
  if response[:statusMessage] == "OK"
    puts "Mailing list entry added for #{email_address}."
  end
rescue Exception => e
  puts "Error occurred while adding entry or it already exists."
  puts e.message
end
