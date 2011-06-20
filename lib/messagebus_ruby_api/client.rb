module MessagebusRubyApi
  DEFAULT_API_ENDPOINT_STRING = 'https://api.messagebus.com:443/v1'

  class Client
    attr_reader :api_key, :endpoint_url, :http

    def initialize(api_key, endpoint_url_string = DEFAULT_API_ENDPOINT_STRING)
      @api_key = verified_reasonable_api_key(api_key)
      @endpoint_url = URI.parse(endpoint_url_string)
      @http = api_endpoint_http_connection(endpoint_url)
      @http.use_ssl = true
    end

    def complete_url(options)
      params_string = to_param(check_params(options))
      url = "/send?operation=sendEmail&#{params_string}&apiKey=#{api_key}"
      url
    end

    def send_email(options)
      verify_required_params(options)
      response = @http.start do |http|
        request = api_request(options)
        request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
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
      params[:priority] = check_priority(params[:priority]) unless params[:priority].nil?
      params
    end

    def to_param(params)
      params.map { |name, val| [name.to_s, val] }.sort.map { |param_name, param_value| "#{CGI.escape(param_name)}=#{CGI.escape(param_value)}" }.join("&")
    end

    def basic_auth_credentials=(credentials)
      @credentials = credentials
    end

    private

    def api_request(options)
      Net::HTTP::Post.new(complete_url(options)) #, {"User-Agent" => "messagebus.com Messagebus Ruby API v1"})
    end    

    def api_endpoint_http_connection(endpoint_url)
      Net::HTTP.new(endpoint_url.host, endpoint_url.port)
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
      raise APIParameterError.new("plaintextBody or htmlBody") unless params[:plaintextBody] || params[:htmlBody]
    end
  end
end
