require 'rubygems'
require 'json'
require 'date'
require 'pp'
require '../lib/messagebus_ruby_api'

# login to demo api
api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusApi::Messagebus.new(api_key)

# send an email with the headers and params set 
params = { :toEmail => 'apitest1@messagebus.com',
      :toName => 'EmailUser',
      :fromEmail => 'api@messagebus.com',
      :fromName => 'API',
      :subject => 'Unit Test Message',
      :customHeaders => {"sender"=>"apitest1@messagebus.com"},
      :plaintextBody => 'This message is only a test sent by the Ruby MessageBus client library.',
      :htmlBody => "<html><body>This message is only a test sent by the Ruby MessageBus client library.</body></html>",
      :tags => ['RUBY', 'Unit Test Ruby']
    }


begin
  client.add_message(params, true)
  if client.results[:statusMessage] == "OK"
    status = client.results
    puts "Successfully sent #{status[:successCount]} messages."
    puts "Message ID: #{status[:results][0][:messageId]}"
  end
rescue Exception => e
  puts "Error occurred while sending messages."
  puts e.message
end

