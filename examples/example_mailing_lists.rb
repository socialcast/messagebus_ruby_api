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

# This example demonstrates various api methods relating to mailing list management.
# We create a new blank mailing list; add two entries to the new list; delete one of
# the entries; and then retrieve the list of all mailing lists

api_key="YOUR_ACCOUNT_API_KEY_GOES_HERE"
client= MessagebusApi::Messagebus.new(api_key)

begin
  # first create a new blank mailing list
  name = 'example mailing list'
  merge_field_keys = ["%EMAIL%", "%FIRST_NAME%", "%LAST_NAME%"]

  status = client.create_mailing_lists(name, merge_field_keys)

  if status[:statusCode] == 201
    mailing_list_key = status[:key]
    puts "A mailing list with key #{mailing_list_key} was created"
  else
    puts "Problem in getting unsubscribe list. #{status[:statusCode]}-#{status[:statusMessage]}"
    exit
  end

  # after the new mailing list is created, add two entries to the list
  email1 = "jane@example.com"
  merge_fields = {"%EMAIL%" => email1, "%FIRST_NAME%" => "Jane", "%LAST_NAME%" => "Smith"}
  status = client.add_mailing_list_entry(mailing_list_key, merge_fields)
  if status[:statusCode] == 201
    puts "Entry #{email1} was added to the mailing list"
  else
    puts "Problem in adding mailing list entry for #{email1}. #{status[:statusCode]}-#{status[:statusMessage]}"
    exit
  end

  email2 = "john@example.com"
  merge_fields = {"%EMAIL%" => email2, "%FIRST_NAME%" => "John", "%LAST_NAME%" => "Doe"}
  status = client.add_mailing_list_entry(mailing_list_key, merge_fields)
  if status[:statusCode] == 201
    puts "Entry #{email2} was added to the mailing list"
  else
    puts "Problem in adding mailing list entry for #{email2}. #{status[:statusCode]}-#{status[:statusMessage]}"
    exit
  end

  # having added two entries, delete one of them
  status = client.delete_mailing_list_entry(mailing_list_key, email2)
  if status[:statusCode] == 200
    puts "Entry #{email2} was deleted from the mailing list"
  else
    puts "Problem deleting mailing list entry for #{email2}. #{status[:statusCode]}-#{status[:statusMessage]}"
    exit
  end

  # list all the mailing lists
  status = client.mailing_lists
  if status[:statusCode] == 200
    puts "The following mailing lists exist:"
    status[:results].each do |list|
      puts "List #{list[:name]} with key #{list[:key]}"
    end
  else
    puts "Problem getting mailing lists. #{status[:statusCode]}-#{status[:statusMessage]}"
    exit
  end

rescue Exception => e
  puts "Error occurred while modifying mailing lists."
  puts e.message
end

