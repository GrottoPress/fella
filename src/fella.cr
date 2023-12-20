require "http/server/handler"
require "uuid"

require "./fella/version"
require "./fella/**"

module Fella
  extend self

  private module Settings
    class_property skip_if : Proc(HTTP::Request, Bool) =
      ->(request : HTTP::Request) do
        request.query_params.any? do |key, _|
          !key.match(/code|password|secret|token/i).nil?
        end
      end
  end

  def settings
    Settings
  end

  def configure : Nil
    yield settings
  end
end
