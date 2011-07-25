module MessagebusRubyApi
  DEFAULT_API_ENDPOINT_STRING = 'https://api.messagebus.com:443'

  class Client
    attr_reader :api_key, :endpoint_url, :http

    def initialize(api_key, endpoint_url_string = DEFAULT_API_ENDPOINT_STRING)
      @api_key = verified_reasonable_api_key(api_key)
      @endpoint_url = URI.parse(endpoint_url_string)
      @endpoint_base_path="/api/v2/emails/"
      @endpoint_path = @endpoint_base_path+"send"
      @endpoint_bulk_path = @endpoint_base_path+"send_emails"
      @http = Net::HTTP.new(@endpoint_url.host, @endpoint_url.port)
      @http.use_ssl = true
    end

    def send_email(options)
      validate(options)
      response = @http.start do |http|
        request = create_api_request(@endpoint_path)
        request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
        request.form_data={'json' => make_json_message_from_list([options],options)}
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

    def bulk_send(message_list, common_options)
      if (message_list.length==0)
        return  {
        :statusMessage => "OK",
        :successCount => 0,
        :failureCount => 0}
      end
      response = @http.start do |http|
        request = create_api_request(@endpoint_bulk_path)
        request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
        request.form_data={'json' => make_json_message_from_list(message_list,common_options)}
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

    def create_api_request(path)
      Net::HTTP::Post.new(path) #, {"User-Agent" => "messagebus.com Messagebus Ruby API v2"})
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
    end

    def make_json_message_from_list(option_list,common_options)
      message_list=[]
      option_list.each do |list_item|
        message_list<<make_json_message(list_item)
      end
      json = {
        :apiKey => @api_key,
        :messageCount => message_list.length,
        :messages => message_list
      }
      json[:fromEmail]=common_options[:fromEmail] if (common_options.has_key? :fromEmail)
      json[:replyTo]=common_options[:replyTo] if (common_options.has_key? :replyTo)
      json[:tags]=common_options[:tags] if (common_options.has_key? :tags)

      json.reject { |k, v| v == nil }.to_json
    end
  end
end
