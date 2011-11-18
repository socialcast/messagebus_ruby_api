module MessagebusApi
  DEFAULT_API_ENDPOINT_STRING = 'https://api.messagebus.com'

  class Messagebus
    attr_writer :send_common_info

    def initialize(api_key, endpoint_url_string = DEFAULT_API_ENDPOINT_STRING)
      @api_key = verified_reasonable_api_key(api_key)

      @http = http_connection(endpoint_url_string)
      @user_agent = "MessagebusAPI:#{MessagebusRubyApi::VERSION}-Ruby:#{RUBY_VERSION}"

      @msg_buffer_size = 20
      @msg_buffer = []
      @msg_buffer_flushed = false
      @send_common_info = {}
      @results = base_response_params
      @rest_endpoints = define_rest_endpoints
      @rest_http_errors = define_rest_http_errors
    end

    def results
      @results
    end

    def message_buffer_size=(size)
      @msg_buffer_size = size if (size >= 1 && size <= 100)
    end

    def message_buffer_size
      @msg_buffer_size
    end

    def flushed?
      @msg_buffer_flushed
    end

    def add_message(msg_options, flush_buffer = false)
      @msg_buffer << msg_options
      @msg_buffer_flushed = false
      if flush_buffer || @msg_buffer.size >= @msg_buffer_size
        flush
      end
      return
    end

    def flush
      if (@msg_buffer.size==0)
        @results=@empty_send_results
        return
      end
      request = create_api_post_request(@rest_endpoints[:emails_send])
      request.form_data={'json' => make_json_message_from_list(@msg_buffer, @send_common_info)}
      @results=make_api_call(request)
      @msg_buffer.clear
      @msg_buffer_flushed = true
      return
    end

    def add_mailing_list_entry(mailing_list_key, merge_fields)
      url = @rest_endpoints[:mailing_lists_entries].gsub("%KEY%", mailing_list_key)
      request = create_api_post_request(url)
      json = {
        "apiKey" => @api_key,
        "mailingListKey" => mailing_list_key,
        "mergeFields" => merge_fields
      }.to_json
      request.form_data={'json' => json}
      make_api_call(request)
    end

    def remove_mailing_list_entry(mailing_list_key, to_email)
      url = @rest_endpoints[:mailing_lists_entry_email].gsub("%KEY%", mailing_list_key).gsub("%EMAIL%", to_email)
      request = create_api_delete_request(url)
      json = {
        "apiKey" => @api_key,
        "mailingListKey" => mailing_list_key,
        "email" => to_email
      }.to_json
      request.form_data={'json' => json}
      make_api_call(request)
    end

    def get_mailing_lists
      request=create_api_get_request(@rest_endpoints[:mailing_lists])
      make_api_call(request)
    end

    def get_error_report
      request=create_api_get_request(@rest_endpoints[:delivery_errors])
      make_api_call(request)
    end

    def get_unsubscribe_results(start_date, end_date=nil)
      start_dt = DateTime.parse(start_date)
      end_dt = DateTime.parse(end_date)
      additional_params="startDate=#{URI.escape("#{start_dt}")}"
      unless (end_date.nil?)
        additional_params+="&endDate=#{URI.escape("#{end_dt}")}"
      end
      url = "#{@rest_endpoints[:unsubscribes]}?#{additional_params}"
      request=create_api_get_request(url)
      make_api_call(request)
    end

    def buffered_send(message_list, common_options)
    end

    private

    def http_connection(endpoint_url_string)
      endpoint_url = URI.parse(endpoint_url_string)
      http = Net::HTTP.new(endpoint_url.host, endpoint_url.port)
      http.use_ssl = true
      http
    end

    def common_http_headers
      {'User-Agent' => @user_agent, 'X-MessageBus-Key' => @api_key}
    end

    def rest_post_headers
      {"Content-Type" => "application/json; charset=utf-8"}
    end

    def create_api_post_request(path)
      Net::HTTP::Post.new(path, common_http_headers.merge(rest_post_headers))
    end

    def create_api_get_request(path)
      Net::HTTP::Get.new(path, common_http_headers)
    end

    def create_api_delete_request(path)
      Net::HTTP::Delete.new(path, common_http_headers)
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
        json["tags"]=common_options[:tags] if (common_options.has_key? :tags)
        json["customHeaders"]=common_options[:customHeaders] if (common_options.has_key? :customHeaders)
        json["templateKey"]=common_options[:templateKey] if (common_options.has_key? :templateKey)
      end

      json.reject { |k, v| v == nil }.to_json
    end

    def make_api_call(request, symbolize_names=true)
      response = @http.start do |http|
        http.request(request)
      end
      case response
        when Net::HTTPSuccess
          begin
            return JSON.parse(response.body, :symbolize_names => symbolize_names)
          rescue JSON::ParserError => e
            raise MessagebusRubyApi::RemoteServerError.new("Remote server returned unrecognized response: #{e.message}")
          end
        when Net::HTTPClientError, Net::HTTPServerError
          if (response.body && response.body.size > 0)
            result = begin
              JSON.parse(response.body, :symbolize_names => symbolize_names)
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

    def define_rest_endpoints
      {
        :emails_send => "/api/v3/emails/send",
        :templates_send => "/api/v3/templates/send",
        :stats => "/api/v3/stats",
        :delivery_errors => "/api/v3/delivery_errors",
        :unsubscribes => "/api/v3/unsubscribes",
        :mailing_lists => "/api/v3/mailing_lists",
        :mailing_lists_entries => "/api/v3/mailing_list/%KEY%/entries",
        :mailing_lists_entry_email => "/api/v3/mailing_list/%KEY%/entry/%EMAIL%",
        :version => "/api/version"
      }
    end

    def define_rest_http_errors
      {
        "400" => "Invalid Request",
        "401" => "Unauthorized-Missing API Key",
        "403" => "Unauthorized-Invalid API Key",
        "404" => "Incorrect URL",
        "405" => "Method not allowed",
        "406" => "Format not acceptable",
        "408" => "Request Timeout",
        "409" => "Conflict",
        "410" => "Object missing or deleted",
        "413" => "Too many messages in request",
        "415" => "POST JSON data invalid",
        "422" => "Unprocessable Entity",
        "500" => "Internal Server Error",
        "501" => "Not Implemented",
        "503" => "Service Unavailable",
        "507" => "Insufficient Storage"
      }
    end

    def base_response_params
      {:statusCode => 0,
       :statusMessage => "",
       :statusTime => "1970-01-01T00:00:00.000Z"}
    end

    def base_message_params
      {:toEmail => '',
       :fromEmail => '',
       :subject => '',
       :toName => '',
       :fromName => '',
       :plaintextBody => '',
       :htmlBody => '',
       :customHeaders => [],
       :tags => [] }
    end

    def base_template_params
      {:toEmail => '',
       :toName => '',
       :templateKey => '',
       :mergeFields => [],
       :customHeaders => [] }
    end

  end
end
