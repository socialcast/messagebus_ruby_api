#require 'net/http'
require 'net/https'
require 'uri'
require 'cgi'

class String
  def camelize
    self.split(/[^a-z0-9]/i).map(&:capitalize).join.tap{|string| string[0,1] = string[0,1].downcase }
  end
end

module MessagebusRubyApi
  API_ENDPOINT = URI.parse('https://api.messagebus.com:443')

  class APIParameterError < StandardError
    def initialize(problematic_parameter="")
      super("missing or malformed parameter #{problematic_parameter}")
    end
  end
  class BadAPIKeyError < StandardError;
  end

  class Client
    attr_reader :api_key

    def camelize(string)
      string.split(/[^a-z0-9]/i).map(&:capitalize).join.tap{|string| string[0,1] = string[0,1].downcase }
    end

    def initialize(api_key)
      @api_key = verified_reasonable_api_key(api_key)
      @http = api_endpoint_http_connection
      @http.use_ssl = true
    end

    def api_endpoint_http_connection
      Net::HTTP.new(API_ENDPOINT.host, API_ENDPOINT.port)
    end

    def api_request(options)
      Net::HTTP::Post.new("/send?operation=send&#{to_param(options)}") #, {"User-Agent" => "messagebus.com Messagebus Ruby API v1"})
    end

    def send_email(options)
      verify_required_params(options)
      response = @http.start do |http|
        request = api_request(options)
#        pp request.
        http.request(request)
      end
#      puts response.body
      raise MessagebusRubyApi::APIParameterError unless response.body.match(/^OK/)
    end

    def to_param(params)
      params.map { |name, val| [name.to_s.camelize, val] }.sort.map{|param_name, param_value| "#{CGI.escape(param_name)}=#{CGI.escape(param_value)}"}.join("&")
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
