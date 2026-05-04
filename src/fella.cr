require "http/server/handler"
require "uuid"

require "./fella/version"
require "./fella/**"

module Fella
  extend self

  private module Settings
    class_property request_id_header : String? = "X-Request-ID"

    class_property sensitive_params : Indexable(String) = {
      "code",
      "password",
      "secret",
      "token"
    }
  end

  def settings
    Settings
  end

  def configure : Nil
    yield settings
  end
end
