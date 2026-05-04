require "http/server/handler"
require "uuid"

require "./fella/version"
require "./fella/**"

module Fella
  extend self

  private module Settings
    class_property filter_params : Indexable(String) = {
      "code",
      "password",
      "secret",
      "token"
    }

    class_property request_id_header : String? = "X-Request-ID"
  end

  def settings
    Settings
  end

  def configure : Nil
    yield settings
  end
end
