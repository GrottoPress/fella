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
      url: request.resource,
      http_version: request.version,
      status_code: response.status_code,
      duration_ms: duration.try(&.total_milliseconds.round.to_i),
      user_agent: request.headers["User-Agent"]?
    }
  end
end
