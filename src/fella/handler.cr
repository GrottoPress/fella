class Fella::Handler
  include HTTP::Handler

  def initialize(@log = HTTP::Server::Log)
  end

  def call(context)
    return call_next(context) if Fella.settings.skip_if.call(context.request)

    duration = Time.measure { call_next(context) }

    if context.response.status_code < 400
      log_succeeded(context, duration)
    else
      log_failed(context, duration)
    end
  rescue error
    log_errored(error, context)
    raise error
  end

  private def log_succeeded(context, duration)
    @log.info &.emit(**log_args(context, duration))
  end

  private def log_failed(context, duration)
    @log.warn &.emit(**log_args(context, duration))
  end

  private def log_errored(error, context)
    @log.error(exception: error, &.emit **log_args(context))
  end

  private def log_args(context, duration = nil)
    request, response = context.request, context.response

    {
      id: UUID.random.hexstring,
      ip_address: request.remote_address.as?(Socket::IPAddress).try(&.address),
      method: request.method,
      url: sanitize_input(request.resource),
      http_version: request.version,
      status_code: response.status_code,
      duration_ms: duration.try(&.total_milliseconds.round.to_i),
      user_agent: user_agent(request),
      referer: referer(request)
    }
  end

  private def user_agent(request)
    request.headers["User-Agent"]?.try { |agent| sanitize_input(agent) }
  end

  private def referer(request)
    request.headers["Referer"]?.try do |referer|
      uri = URI.parse(referer)

      uri.query = nil
      uri.user = nil
      uri.password = nil
      uri.fragment = nil

      sanitize_input(uri.to_s)
    end
  end

  private def sanitize_input(input)
    input[0, 512].gsub(/\p{C}+/, ' ').strip
  end
end
