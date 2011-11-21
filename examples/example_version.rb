require 'rubygems'
require 'json'
require 'date'
require 'pp'
require '../lib/messagebus_ruby_api'

# no key required
api_key=""
client= MessagebusApi::Messagebus.new(api_key)

# get current version of the api server
begin
  response=client.api_version
  if response[:statusCode] == 200
    puts "API Version is #{response[:APIVersion]}."
  end
rescue Exception => e
  puts "Error occurred while retrieving version from api server."
  puts e.message
end
