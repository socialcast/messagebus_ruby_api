module MessagebusRubyApi
  DEFAULT_API_ENDPOINT_STRING = 'https://api.messagebus.com:443'

  class Client
    attr_reader :api_key, :endpoint_url, :http

    def initialize(api_key, endpoint_url_string = DEFAULT_API_ENDPOINT_STRING)
      @api_key = verified_reasonable_api_key(api_key)
      @endpoint_url = URI.parse(endpoint_url_string)
      @endpoint_path = "/api/v2/emails/send"
      @http = Net::HTTP.new(@endpoint_url.host, @endpoint_url.port)
      @http.use_ssl = true
    end

    def send_email(options)
      validate(options)
      response = @http.start do |http|
        request = create_api_request
        request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
        request.form_data={'json' => make_json_message(options)}
        http.request(request)
      end
      case response
        when Net::HTTPSuccess
          begin
            return JSON.parse(response.body, :symbolize_names => true)
          rescue JSON::ParserError => e
            raise MessagebusRubyApi::RemoteServerError.new("Remote server returned unrecognized response: #{e.message}")
          end
        when Net::HTTPClientError, Net::HTTPServerError
          if (response.body && response.body.size > 0)
            result = begin
              JSON.parse(response.body, :symbolize_names => true)
            rescue JSON::ParserError
              nil
            end
            raise MessagebusRubyApi::RemoteServerError.new("Remote Server Returned: #{response.code.to_s}.  #{result[:statusMessage] if result}", result)
          else
            raise MessagebusRubyApi::RemoteServerError.new("Remote Server Returned: #{response.code.to_s}")
          end
        else
          raise "Unexpected HTTP Response: #{response.class.name}"
      end
      raise "Could not determine response"
    end

    def basic_auth_credentials=(credentials)
      @credentials = credentials
    end

    private

    def create_api_request
      Net::HTTP::Post.new(@endpoint_path) #, {"User-Agent" => "messagebus.com Messagebus Ruby API v2"})
    end

    def check_priority(priority)
      raise APIParameterError.new(":priority can only be an integer between 1 and 5, not \"#{priority}\"") unless priority.is_a?(Integer) && (1..5).include?(priority)
      priority.to_s
    end

    def verified_reasonable_api_key(api_key)
      raise BadAPIKeyError unless api_key.match(/^[a-zA-Z0-9]{32}$/)
      api_key
    end

    def validate(params)
      raise APIParameterError.new("toEmail") unless params[:toEmail]
      raise APIParameterError.new("fromEmail") unless params[:fromEmail]
      raise APIParameterError.new("subject") unless params[:subject]
      raise APIParameterError.new("plaintextBody or htmlBody") unless params[:plaintextBody] || params[:htmlBody]
      params[:priority] = check_priority(params[:priority]) unless params[:priority].nil?
    end

    def make_json_message(options)
      message = {
        :toEmail => options[:toEmail],
        :subject => options[:subject],
        :plaintextBody => options[:plaintextBody],
        :htmlBody => options[:htmlBody]
      }
      json = {
        :apiKey => @api_key,
        :fromEmail => options[:fromEmail],
        :replyTo => options[:replyTo],
        :tags => options[:tags],
        :messageCount => 1,
        :messages => [message]
      }
      json.reject { |k, v| v == nil }.to_json
    end
  end
end
