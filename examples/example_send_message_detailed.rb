require 'rubygems'
require 'json'
require 'date'
require 'pp'
require '../lib/messagebus_ruby_api'

# Make single instance of class to only ma
# If you are sending messages from various points across your code, using a single "MessageBus"
# object instance will efficiently batch transactions, resulting in higher throughput.

class MessagebusInstance < MessagebusApi::Messagebus
  def initialize
    api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
    @client = MessagebusApi::Messagebus.new(api_key)
  end
  def self.instance
    @@instance = MessagebusInstance.new
  end

  def client
    @client
  end
end

client = MessagebusInstance.instance.client

# send an email with the headers and params set
message1 = { :toEmail => 'jane.smieth@example.com',
      :toName => 'Jane Smith',
      :fromEmail => 'noreply@messagebus.com',
      :fromName => 'Example Corporation',
      :subject => 'Single Message Sample for Jane Smith',
      :customHeaders => {"sender"=>"mailing_system@example.com","reply-to"=>"reply@example.com"},
      :plaintextBody => 'This message is only a test sent by the Ruby MessageBus client library.',
      :htmlBody => "<html><body>This message is only a test sent by the Ruby MessageBus client library.</body></html>",
      :tags => ['RUBY', 'campaign_id_1', 'recent_users']
    }

message2 = { :toEmail => 'john.doe@example.com',
      :toName => 'John Doe',
      :fromEmail => 'noreply@messagebus.com',
      :fromName => 'Example Corporation',
      :subject => 'Single Message Sample for John Doe',
      :customHeaders => {"sender"=>"mailing_system@example.com","reply-to"=>"reply@example.com"},
      :plaintextBody => 'This message is only a test sent by the Ruby MessageBus client library.',
      :htmlBody => "<html><body>This message is only a test sent by the Ruby MessageBus client library.</body></html>",
      :tags => ['RUBY', 'campaign_id_1', 'recent_users']
    }

# The MessageBus API buffers email in a local queue to increase performance.  When size of the local queue
# reaches a threshold (default is 20), the messages are automatically flushed and sent.  Remaining queued
# messages are sent when the API instance is closed or destructed.  In the
# example below, we call the flush() explicitly just for example.
begin
  client.add_message(message1)
  client.add_message(message2)

  client.flush

  status = client.results
  puts "Successes: #{status[:successCount]}"
  puts "Failuers: #{status[:failureCount]}"

  # In this example, we loop over each row of the "results" array to provide feedback for each message sent
  if status[:statusCode] == 202
    puts "Message sent successfully"
    status[:results].each do |result|
      puts "Message to #{result[:toEmail]} MessageId: #{result[:messageId]}"
    end
  else
    puts "Problem in sending messages. #{status[:statusCode]}-#{status[:statusMessage]}"
  end
rescue Exception => e
  puts "Error occurred while sending messages."
  puts e.message
end

