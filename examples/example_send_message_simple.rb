# Copyright (c) 2011. Message Bus
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License

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
      :subject => 'Example Test Message',
      :customHeaders => {"sender"=>"apitest1@messagebus.com"},
      :plaintextBody => 'This message is only a test sent by the Ruby MessageBus client library.',
      :htmlBody => "<html><body>This message is only a test sent by the Ruby MessageBus client library.</body></html>",
      :tags => ['RUBY']
    }

# Send message with flush flag set to true.
# Status Code of 202 is the expected response to the REST call
begin
  client.add_message(params, true)
  if client.results[:statusCode] == 202
    status = client.results
    puts "Successfully sent #{status[:successCount]} messages."
    puts "Message ID: #{status[:results][0][:messageId]}"
  end
rescue Exception => e
  puts "Error occurred while sending messages."
  puts e.message
end

