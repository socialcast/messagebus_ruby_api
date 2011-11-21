module MessagebusRubyApi

  class APIParameterError < StandardError
    def initialize(problematic_parameter="")
      super("missing or malformed parameter #{problematic_parameter}")
    end
  end

  class BadAPIKeyError < StandardError
  end

  class MissingFileError <StandardError
  end

  class RemoteServerError < StandardError
    attr_reader :result
    def initialize(message, result={})
      super(message)
      @result = result
    end
  end
  
end