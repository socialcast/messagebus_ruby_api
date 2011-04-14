module MessagebusRubyApi

  class APIParameterError < StandardError
    def initialize(problematic_parameter="")
      super("missing or malformed parameter #{problematic_parameter}")
    end
  end

  class BadAPIKeyError < StandardError;
  end

  class UnknownError < StandardError;
  end
  
end