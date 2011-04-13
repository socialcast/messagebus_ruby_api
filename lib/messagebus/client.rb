#require 'net/http'
require 'net/https'
require 'uri'


module MessageBus
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

    def send_email(options)
      raise APIParameterError unless verify_required_params(options)
      response = @http.start do |http|
        request = Net::HTTP::Post.new("/send&operation=send&#{to_param(options)}")#, {"User-Agent" => "messagebus.com MessageBus Ruby API v1"})
        http.request(request)
      end
      raise MessageBus::APIParameterError unless response.body.match(/^OK/)
    end

    def to_param(params)
      params.map{|name,val|[name.to_s,val]}.sort.map { |param_name, param_value| "#{CGI.escape(param_name)}=#{CGI.escape(param_value)}" }.join("&")
    end

    private

    def verified_reasonable_api_key(api_key)
      raise BadAPIKeyError unless api_key.match(/[a-zA-Z0-9]{20}/)
      api_key
    end

    def verify_required_params(params)
      params[:to_email] && params[:from_email] && params[:body] && params[:subject]
    end
  end
end