require "../spec_helper"

describe Fella::Handler do
  it "logs requests" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        HTTP::Client.get server.uri("/success")
        HTTP::Client.get server.uri("/failure")

        logs.check(:info, "")
        logs.check(:warn, "")
      end
    end
  end

  it "skips logs for sensitive requests" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        HTTP::Client.get server.uri("/success?token=a1b2c3")

        logs.empty
      end
    end
  end

  it "logs errors" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        response = HTTP::Client.get server.uri("/exception")
      rescue
        logs.check(:error, "")
      end
    end
  end
end
