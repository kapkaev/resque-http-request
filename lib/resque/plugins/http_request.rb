require 'faraday'
require "resque/plugins/http_request_status"
require 'resque-retry'

module Resque
  module Plugins
    class HttpRequest
      extend Resque::Plugins::HttpRequestStatus
      extend Resque::Plugins::Retry

      def self.create_connection(url)
        raise ArgumentError, 'URL required' if url.nil?
        connection = Faraday.new(:url => url) do |c|
          c.use Faraday::Request::UrlEncoded  # encode request params as "www-form-urlencoded"
          # c.use Faraday::Response::Logger     # log request & response to STDOUT
          c.use Faraday::Adapter::NetHttp     # perform requests with Net::HTTP
        end
      end


      def self.perform(url, method = :get, params={}, body = nil)
        if params.is_a? String
          params = Hash[params.gsub(/' '|{|}/,'').split(",").map{|x| x.split(":")}]
        end
        @response = create_connection(url).run_request(method.to_sym, nil, body, params)
      end
    end
  end
end