struct AppServer
  private HOST = "127.0.0.1"
  private PORT = 5000

  def initialize
    @server = HTTP::Server.new([log_handler, route_handler]) do |context|
      context.response.content_type = "text/plain"
      context.response.print "Hello, World!"
    end
  end

  def listen
    @server.bind_tcp(HOST, PORT, reuse_port: true)
    @server.listen
  end

  def listen
    listen_async
    yield self
    close
  end

  def listen_async
    spawn { listen }

    until @server.listening?
      Fiber.yield
    end
  end

  def close
    @server.close
  end

  def uri(path = "/")
    "http://#{HOST}:#{PORT}/#{path.lchop("/")}"
  end

  def self.log
    Log.for(self)
  end

  private def log_handler
    Fella::Handler.new(self.class.log)
  end

  private def route_handler
    RouteHandler.new
  end

  private class RouteHandler
    include HTTP::Handler

    def call(context)
      request, response = context.request, context.response

      case request.path
      when "/success"
        response.status_code = 200
        response.puts "Hello, World!"
      when "/failure"
        response.status_code = 400
        response.puts "Bah, Humbug!"
      when "/exception"
        response.status_code = 500
        raise "Oh, Boy!"
      else
        call_next(context)
      end
    end
  end
end
