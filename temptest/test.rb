dir = File.dirname(__FILE__)
require "#{dir}/../lib/messagebus_ruby_api"
require 'json'

client = MessagebusRubyApi::Client.new("919AD8C0038149091CDFCC272ED5BD4B","https://apitest.messagebus.com")
#client.common_info={:fromEmail => "zak@messagebus.com"}
#required_params = {:toEmail => "zak@messagebus.com", :fromEmail => "zak@messagebus.com", :plaintextBody => "a nice ocean", :subject => "test subject"}
#client.add_message(required_params)
#client.flush
#client.send_email required_params

client.common_info={:templateKey => "04ED4DD0A424012E1CCF40400B2CF517"}
required_params = {  :mergeFields => {"%EMAIL%"=>"zak@messagebus.com","%GREETING%"=>"fasdfasdasdf","%SUBJECT%"=>"rewqr"}}
client.add_message(required_params)
client.flush