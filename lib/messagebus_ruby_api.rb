#require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'

require 'messagebus_ruby_api/errors'
require 'messagebus_ruby_api/core_extensions'

module MessagebusRubyApi
  API_ENDPOINT = URI.parse('https://api.messagebus.com:443')

  class Client
    attr_reader :api_key

    def initialize(api_key)
      @api_key = verified_reasonable_api_key(api_key)
      @http = api_endpoint_http_connection
      @http.use_ssl = true
    end

    def api_endpoint_http_connection
      Net::HTTP.new(API_ENDPOINT.host, API_ENDPOINT.port)
    end

    def complete_url(options)
      url = "/send?operation=sendEmail&#{to_param(options)}"
 #     puts "actual   #{url}"
      url
    end

    def api_request(options)
      Net::HTTP::Post.new(complete_url(options)) #, {"User-Agent" => "messagebus.com Messagebus Ruby API v1"})
    end

    def send_email(options)
      verify_required_params(options)
      response = @http.start do |http|
        request = api_request(options)
        http.request(request)
      end

      puts response.body
      raise MessagebusRubyApi::UnknownError unless response.body.match(/^OK/)
      response
    end

    def to_param(params)
      output = params.map { |name, val| [name.to_s.camelize, val] }.sort.map{|param_name, param_value| "#{CGI.escape(param_name)}=#{CGI.escape(param_value)}"}.join("&")
#      puts "to_param #{output}"
      output
    end

    private

    def verified_reasonable_api_key(api_key)
      raise BadAPIKeyError unless api_key.match(/[a-zA-Z0-9]{20}/)
      api_key
    end

    def verify_required_params(params)
      raise APIParameterError.new("to_email") unless params[:to_email]
      raise APIParameterError.new("from_email") unless params[:from_email]
      raise APIParameterError.new("subject") unless params[:subject]
      raise APIParameterError.new("body") unless params[:body]
    end
  end
end
