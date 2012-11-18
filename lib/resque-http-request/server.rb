require 'resque/server'
require "resque/plugins/http_request_status"

module Resque
  module HttpResquestStatusServer
    # pages: performed, failure, main
    VIEW_PATH = File.join(File.dirname(__FILE__), 'server', 'views')

    def self.registered(app)
      app.get '/http_request_status' do
        redirect url_path("/http_request_status/performed")
      end

      app.get "/http_request_status/:key" do
        @start = params[:start].to_i
        @offset = @start + (params[:per_page] || 20)

        @data = case params[:key]
        when "performed"
          data(performed_key, @start, @offset)
        when "failure"
          data(failure_key, @start, @offset)
        end

        @size = @data.size
        page_view(:main)
      end

      app.post '/http_request_status/clear/:key' do
        case params[:key]
        when "all"
          clear_all_http_requests_stats
        when "performed"
          clear_request_stats_list(performed_key)
        when "failure"
          clear_request_stats_list(failure_key)
        end
        redirect url_path("/http_request_status/all")
      end


      app.helpers do
        def page_view(filename, options = {}, locals = {})
          erb(File.read(File.join(::Resque::HttpResquestStatusServer::VIEW_PATH, "#{filename}.erb")), options, locals)
        end

        def performed_key
          Resque::Plugins::HttpRequestStatus::PERFORMED_KEY
        end

        def failure_key
          Resque::Plugins::HttpRequestStatus::FAILURE_KEY
        end

        def list_count(key)
          Resque.redis.llen(key)
        end

        def clear_request_stats_list(key)
          Resque.redis.del(key)
        end

        def clear_all_http_requests_stats
          clear_request_stats_list(performed_key)
          clear_request_stats_list(failure_key)
        end

        def data(key, start, offset)
          Resque.redis.lrange(key, start || 0, offset || start+20).map{|r| Resque.decode(r)}
        end
      end
      app.tabs << "http_request_status"
    end
  end
end

Resque::Server.register Resque::HttpResquestStatusServer
