module Resque
  module Plugins
    module HttpRequestStatus
      PERFORMED_KEY = "stats:http_request:performed:list"
      FAILURE_KEY = "stats:http_request:failure:list"

      def before_perform_http_resquest(*args)
      end

      def on_failure_http_resquest(exception, *args)
        custom_exception = {exception: exception}
        custom_exception.merge!(type: exception.class.name,
                                message: exception.message,
                                date: Time.now.rfc2822,
                                backtrace: exception.backtrace.join("\n"))
        Resque.redis.rpush(FAILURE_KEY, Resque.encode(response_data(exception: custom_exception, args: args)))
      end

      # Increments the performed count when job is complete
      def after_perform_http_resquest(*args)
        Resque.redis.rpush(PERFORMED_KEY, Resque.encode(response_data(args: args)))
      end

      def response_data(additional_data = {})
        response_data = self.instance_variable_get(:@response)
        data = if response_data
            response_data.to_hash.merge!(additional_data)
          elsif not additional_data.empty?
            additional_data
          else
            {}
        end

        keys = [:status, :method ,:response_headers, :exception, :exception_type, :exception_message, :backtrace, :args]
        data.delete_if{|k,v| !keys.include? k}

        data.merge!(name: self.name)

      end

    end
  end
end