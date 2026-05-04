class Fella::Handler
  include HTTP::Handler

  def initialize(@log = HTTP::Server::Log)
  end

  def call(context)
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
      request_id: request_id(request),
      ip_address: request.remote_address.as?(Socket::IPAddress).try(&.address),
      method: request.method,
      url: sanitize_input(redact_url request),
      http_version: request.version,
      status_code: response.status_code,
      body_bytes: content_length(response),
      duration_ms: duration.try(&.total_milliseconds.round.to_i),
      user_agent: user_agent(request),
      referer: referer(request)
    }
  end

  private def content_length(response)
    response.headers["Content-Length"]?.try(&.to_i64)
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

  private def request_id(request)
    Fella.settings.request_id_header.try do |header|
      request.headers[header]?.try { |request_id| sanitize_input(request_id) }
    end
  end

  private def user_agent(request)
    request.headers["User-Agent"]?.try { |agent| sanitize_input(agent) }
  end

  private def redact_url(request)
    sensitive_params = Fella.settings.sensitive_params
    return request.uri.to_s if sensitive_params.empty?

    query = URI::Params.build do |form|
      request.query_params.each do |name, value|
        if sensitive_params.any? { |key| name.downcase.includes?(key.downcase) }
          form.add(name, "REDACTED")
        else
          form.add(name, value)
        end
      end
    end

    URI.new(
      request.uri.scheme,
      request.uri.host,
      request.uri.port,
      request.uri.path,
      query.empty? ? nil : query,
      request.uri.user,
      request.uri.password,
      request.uri.fragment
    ).request_target
  end

  private def sanitize_input(input)
    input[0, 512].gsub(/\p{C}+/, ' ').strip
  end
end
