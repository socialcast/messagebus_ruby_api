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

# define one or more template message param arrays.
template1 = { :toEmail => 'jane.smith@example.com',
      :toName => 'Jane Smith',
      :templateKey => '99C20520A72F012EB1804040FFCE8AA7',
      :mergeFields => {"%FIRST_NAME%"=>"Jane","%LAST_NAME%"=>"Smith"},
      :customHeaders => {"sender"=>"mailing_system@example.com","reply-to"=>"reply@example.com"}
    }

# use a different template than above with different merge fields
template2 = { :toEmail => 'john.doe@example.com',
      :toName => 'John Doe',
      :templateKey => '00C20520A72F012EB1804040FFCE8ZZZ',
      :mergeFields => {"%SALUTATION%" => "Hey there!","%TITLE%"=>"Dr.","%NAME%"=>"John Doe"},
      :customHeaders => {"sender"=>"mailing_system@example.com","reply-to"=>"reply@example.com"}
    }

# The MessageBus API buffers email in a local queue to increase performance.  When size of the local queue
# reaches a threshold (default is 20), the messages are automatically flushed and sent.  Remaining queued
# messages are sent when the API instance is closed or destructed.  In the
# example below, we call the flush() explicitly just for example.
begin
  client.add_message(template1)
  client.add_message(template2)

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

