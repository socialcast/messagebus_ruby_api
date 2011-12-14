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
