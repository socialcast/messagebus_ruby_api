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
      params_string = to_param(check_params(options))
      url = "/send?operation=sendEmail&#{params_string}"
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
      case response
        when Net::HTTPSuccess
          return response
        when Net::HTTPClientError, Net::HTTPServerError
          if (response.body && response.body.size > 0)
            raise MessagebusRubyApi::RemoteServerError.new(response.body)
          else
            raise MessagebusRubyApi::RemoteServerError.new("ERR:Remote Server Returned: #{response.code.to_s}")
          end
        else
          raise "Unexpected HTTP Response: #{response.class.name}"
      end
      raise "Could not determine response"
    end

    def check_params(params)
      params[:plainText] = check_plain_text(params[:plainText]) unless params[:plainText].nil?
      params[:priority] = check_priority(params[:priority]) unless params[:priority].nil?
      params
    end

    def to_param(params)
      params.map { |name, val| [name.to_s, val] }.sort.map { |param_name, param_value| "#{CGI.escape(param_name)}=#{CGI.escape(param_value)}" }.join("&")
    end

    private

    def check_plain_text(plain_text)
      raise APIParameterError.new(":plainText can only be true or false, not \"#{plain_text}\" of type #{plain_text.class}") unless [true, false].include?(plain_text)
      plain_text ? "1" : "0"
    end

    def check_priority(priority)
      raise APIParameterError.new(":priority can only be an integer between 1 and 5, not \"#{priority}\"") unless priority.is_a?(Integer) && (1..5).include?(priority)
      priority.to_s
    end

    def verified_reasonable_api_key(api_key)
      raise BadAPIKeyError unless api_key.match(/^[a-zA-Z0-9]{32}$/)
      api_key
    end

    def verify_required_params(params)
      raise APIParameterError.new("toEmail") unless params[:toEmail]
      raise APIParameterError.new("fromEmail") unless params[:fromEmail]
      raise APIParameterError.new("subject") unless params[:subject]
      raise APIParameterError.new("body") unless params[:body]
    end
  end
end
