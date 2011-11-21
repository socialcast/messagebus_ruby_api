module MessagebusApi
  DEFAULT_API_ENDPOINT_STRING = 'https://api.messagebus.com'

  class Messagebus
    TEMPLATE = 'template'
    EMAIL= 'email'

    attr_writer :send_common_info

    def initialize(api_key)
      @api_key = api_key

      @http = http_connection(DEFAULT_API_ENDPOINT_STRING)
      @user_agent = "MessagebusAPI:#{MessagebusRubyApi::VERSION}-Ruby:#{RUBY_VERSION}"

      @msg_buffer_size = 20
      @msg_buffer = []
      @msg_type = nil
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

    def api_version
      make_api_get_call(@rest_endpoints[:version])
    end

    def add_message(params, flush_buffer = false)
      if params.key?(:templateKey)
        add_template_message(params)
      else
        add_email_message(params)
      end

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

      if @msg_type == TEMPLATE
        endpoint = @rest_endpoints[:templates_send]
      else
        endpoint = @rest_endpoints[:emails_send]
      end

      json = json_message_from_list(@msg_buffer)
      @results=make_api_post_call(endpoint, json)
      @msg_buffer.clear
      @msg_buffer_flushed = true
      return
    end

    def mailing_lists
      make_api_get_call(@rest_endpoints[:mailing_lists])
    end

    def create_mailing_lists(list_name, merge_field_keys)
      json = {:name => list_name, :mergeFieldKeys => merge_field_keys}.to_json
      @results = make_api_post_call(@rest_endpoints[:mailing_lists], json)
      @results
    end

    def delete_mailing_list_entry(mailing_list_key, email)
      path = @rest_endpoints[:mailing_lists_entry_email].gsub("%KEY%", mailing_list_key).gsub("%EMAIL%", email)
      @results = make_api_delete_call(path)
      @results
    end

    def add_mailing_list_entry(mailing_list_key, merge_fields)
      path = @rest_endpoints[:mailing_lists_entries].gsub("%KEY%", mailing_list_key)
      json = {:mergeFields => merge_fields}.to_json
      @results = make_api_post_call(path, json)
      @results
    end

    def unsubscribes(start_date = '', end_date = '')
      end_date = set_date(end_date, 0)
      start_date = set_date(start_date, 7)
      path = "#{@rest_endpoints[:unsubscribes]}?#{date_range(start_date, end_date)}"
      @results = make_api_get_call(path)
      @results
    end

    def delivery_errors(start_date = '', end_date = '')
      end_date = set_date(end_date, 0)
      start_date = set_date(start_date, 1)
      path = "#{@rest_endpoints[:delivery_errors]}?#{date_range(start_date, end_date)}"
      @results = make_api_get_call(path)
      @results
    end

    def stats(start_date = '', end_date = '', tag = '')
      end_date = set_date(end_date, 0)
      start_date = set_date(start_date, 30)
      path = "#{@rest_endpoints[:stats]}?#{date_range(start_date, end_date)}&tag=#{tag}"
      @results = make_api_get_call(path)
      @results
    end

    def cacert_info(cert_file)
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      if !File.exists?(cert_file)
        raise MessagebusRubyApi::MissingFileError.new("Unable to read file #{cert_file}")
      end
      @http.ca_file = File.join(cert_file)
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

    def add_email_message(params)
      @msg_type = EMAIL if @msg_type == nil
      @msg_buffer << base_message_params.merge!(params)

    end

    def add_template_message(params)
      @msg_type = TEMPLATE if @msg_type == nil
      @msg_buffer << base_template_params.merge!(params)
    end

    def date_range(start_date, end_date)
      "startDate=#{start_date}&endDate=#{end_date}"
    end

    def set_date(date_string, days_ago)
      if date_string.length == 0
        return date_str_for_time_range(days_ago)
      end
      date_string
    end

    def date_str_for_time_range(days_ago)
      (Time.now.utc - (days_ago*86400)).strftime("%Y-%m-%d")
    end

    def json_message_from_list(messages)
      {:messages => messages}.to_json
    end

    def make_api_post_call(path, data)
      headers = common_http_headers.merge(rest_post_headers)
      response = @http.request_post(path, data, headers)
      check_response(response)
    end

    def make_api_get_call(path)
      headers = common_http_headers
      response = @http.request_get(path, headers)
      check_response(response)
    end

    def make_api_delete_call(path)
      headers = common_http_headers
      response = @http.delete(path, headers)
      check_response(response)
    end

    def check_response(response, symbolize_names=true)
      case response
        when Net::HTTPSuccess
          begin
            return JSON.parse(response.body, :symbolize_names => symbolize_names)
          rescue JSON::ParserError => e
            raise MessagebusRubyApi::RemoteServerError.new("JSON parsing error.  Response started with #{response.body.slice(0..9)}")
          end
        when Net::HTTPClientError, Net::HTTPServerError
          if (response.body && response.body.size > 0)
            result = begin
              JSON.parse(response.body, :symbolize_names => symbolize_names)
            rescue JSON::ParserError
              nil
            end
            raise MessagebusRubyApi::RemoteServerError.new("#{response.code.to_s}:#{rest_http_error_message(response.code.to_s)}")
          else
            raise MessagebusRubyApi::RemoteServerError.new("#{response.code.to_s}:#{rest_http_error_message(response.code.to_s)}")
          end
        else
          raise "Unexpected HTTP Response: #{response.class.name}"
      end
      raise "Could not determine response"
    end

    def rest_http_error?(status_code)
      @rest_http_errors.key?(status_code)
    end

    def rest_http_error_message(status_code)
      message = "Unknown Error Code"
      message = @rest_http_errors[status_code] if rest_http_error?(status_code)
      message
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
       :customHeaders => {},
       :tags => [] }
    end

    def base_template_params
      {:toEmail => '',
       :toName => '',
       :templateKey => '',
       :mergeFields => {},
       :customHeaders => {} }
    end

  end
end
