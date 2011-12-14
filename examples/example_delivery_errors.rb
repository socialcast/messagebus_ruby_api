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

# retrieves message delivery errors
# the delivery_errors method optionally accepts startDate and endDate parameters which define the
# range of dates to supply delivery errors for.  if these parameters are not supplied, startDate
# defaults to 7 days ago and endDate defaults to today.  Format date strings as YYYY-MM-DD.
begin
  start_date_str="2011-01-01"
  end_date_str="2011-01-02"
  status = client.delivery_errors(start_date_str, end_date_str)

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

