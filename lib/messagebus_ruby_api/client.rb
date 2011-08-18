module MessagebusRubyApi
  DEFAULT_API_ENDPOINT_STRING = 'https://api.messagebus.com:443'

  class Client
    attr_reader :api_key, :endpoint_url, :http
    attr_reader :email_buffer, :send_return_status, :email_buffer_size
    attr_writer :send_common_info
    @empty_send_results=nil

    def initialize(api_key, endpoint_url_string = DEFAULT_API_ENDPOINT_STRING)
      @api_key = verified_reasonable_api_key(api_key)
      @endpoint_url = URI.parse(endpoint_url_string)
      @endpoint_send_path = "/api/v2/emails/send"
      @endpoint_error_report_path = "/api/v2/emails/error_report"
      @http = Net::HTTP.new(@endpoint_url.host, @endpoint_url.port)
      @http.use_ssl = true

      @email_buffer_size=20
      @email_buffer=[]
      @empty_send_results= {
        :statusMessage => "",
        :successCount => 0,
        :failureCount => 0,
        :results => []
      }
      @send_return_status=@empty_send_results
      @send_common_info={}
    end

    def add_message(email_options)
      @email_buffer<<email_options
      if (@email_buffer.size >= @email_buffer_size)
        self.flush
        return 0
      else
        return @email_buffer.size
      end
    end

    def flush
      if (@email_buffer.size==0)
        @send_return_status=@empty_send_results
        return
      end
      @send_return_status=self.buffered_send(@email_buffer, @send_common_info)
      @email_buffer.clear
      @send_return_status
    end

    def error_report
      request=create_api_get_request("#{@endpoint_error_report_path}?apiKey=#{@api_key}")
      request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
      self.make_api_call(request)
    end

    def basic_auth_credentials=(credentials)
      @credentials = credentials
    end

    def create_api_post_request(path)
      Net::HTTP::Post.new(path)
    end

    def create_api_get_request(path)
      Net::HTTP::Get.new(path)
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

    def buffered_send(message_list, common_options)
      if (message_list.length==0)
        return {
          :statusMessage => "OK",
          :successCount => 0,
          :failureCount => 0}
      end
      request = create_api_post_request(@endpoint_send_path)
      request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
      request.form_data={'json' => make_json_message_from_list(message_list, common_options)}
      self.make_api_call(request)
    end

    def make_json_message(options)
      map={}
      map["toEmail"]=options[:toEmail] if (options.has_key? :toEmail)
      map["toName"]=options[:toName] if (options.has_key? :toName)
      map["subject"]=options[:subject] if (options.has_key? :subject)
      map["plaintextBody"]=options[:plaintextBody] if (options.has_key? :plaintextBody)
      map["htmlBody"]=options[:htmlBody] if (options.has_key? :htmlBody)
      map["fromName"]=options[:fromName] if (options.has_key? :fromName)
      map["tag"]=options[:tag] if (options.has_key? :tag)
      map["replyTo"]=options[:replyTo] if (options.has_key? :replyTo)
      map["mergeFields"]=options[:mergeFields] if (options.has_key? :mergeFields)
      map
    end

    def make_json_message_from_list(option_list, common_options)
      message_list=[]
      option_list.each do |list_item|
        message_list<<make_json_message(list_item)
      end
      json = {
        "apiKey" => @api_key,
        "messageCount" => message_list.length,
        "messages" => message_list
      }
      if (common_options!=nil)
        json["fromEmail"]=common_options[:fromEmail] if (common_options.has_key? :fromEmail)
        json["fromName"]=common_options[:fromName] if (common_options.has_key? :fromName)
        json["replyTo"]=common_options[:replyTo] if (common_options.has_key? :replyTo)
        json["tags"]=common_options[:tags] if (common_options.has_key? :tags)
        json["customHeaders"]=common_options[:customHeaders] if (common_options.has_key? :customHeaders)
        json["templateKey"]=common_options[:templateKey] if (common_options.has_key? :templateKey)
      end

      json.reject { |k, v| v == nil }.to_json
    end

    def make_api_call(request)
      response = @http.start do |http|
        request.basic_auth(@credentials[:user], @credentials[:password]) if @credentials
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
  end
end
