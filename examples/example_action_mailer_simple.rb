# Copyright (c) 2011. Message Bus
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License
                                                                                                                                                                                                                                
# simple example illustrating MessageBus Ruby API and ActionMailer
# uncomment code and place in indicated files for bare bones Rails/ActionMailer set up
#
# _______________________________________________________________________________________________
# in ../config/environments/development.rb and/or production.rb

#  require 'messagebus/mb_actionmailer_example.rb'
#
#  config.action_mailer.delivery_method = MB_ActionMailerExample.new("Your API Key goes here")
#  config.action_mailer.raise_delivery_errors = true   # helpful for debugging
# _______________________________________________________________________________________________

# _______________________________________________________________________________________________
# ../controllers/send_mail_controller.rb
#class SendMailController < ApplicationController
#  def sendmail
#    Notifier.greeting_email("test@testdomain.com").deliver
#  end
#end
# _______________________________________________________________________________________________

# _______________________________________________________________________________________________
# ../mailers/notifier.rb
#class Notifier < ActionMailer::Base
#  def greeting_email(email)
#    mail(:to => email, :from => "bob@example.com", :subject => "Greetings from Bob")
#  end
#end
# _______________________________________________________________________________________________

# Use the following templates for multipart messages, which ActionMailer detects and
# sets message.multipart=true
# _______________________________________________________________________________________________
# ../views/notifier/greeting_email.html.erb
#<!DOCTYPE html>
#<html>
#  <head>
#    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
#  </head>
#  <body>
#    <h1>Welcome to example.com</h1>
#    <p>
#    <p>Thanks for visiting!</p>
#  </body>
#</html>
#_______________________________________________________________________________________________
# ../views/notifier/greeting_email.text.erb
#Welcome to example.com
#
#Thanks for visiting!
#_______________________________________________________________________________________________


# _______________________________________________________________________________________________
# ../lib/messagebus/mb_actionmailer_example.rb

require 'messagebus_ruby_api'

class MB_ActionMailerExample
  def new(api_key)
    self
  end

  def initialize(api_key)
    @client = MessagebusApi::Messagebus.new(api_key)
  end

  def deliver!(message)
    msg = {:toEmail => message.to.first, :subject => message.subject, :fromEmail =>message.from.first}

    if message.multipart?
      msg[:plaintextBody] = message.text_part.body.to_s if message.text_part
      msg[:htmlBody] = message.html_part.body.to_s if message.html_part
    end

    begin
      @client.add_message(msg, true)
    rescue => message_bus_api_error
      raise "Messagebus API error=#{message_bus_api_error}, message=#{msg.inspect}"
    end
  end
end