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
        HTTP::Client.get server.uri("/exception")
      rescue
        logs.check(:error, "")
      end
    end
  end

  it "sanitizes URL" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        HTTP::Client.get server.uri("/test\tfoo")
        logs.check(:info, "")
        logs.entry.data[:url].to_s.should eq("/test foo")
      end
    end
  end

  it "truncates long URL" do
    long_path = "/" + "a" * 600
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        HTTP::Client.get server.uri(long_path)
        logs.check(:info, "")
        logs.entry.data[:url].to_s.size.should be <= 512
      end
    end
  end

  it "sanitizes User-Agent" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        headers = HTTP::Headers{"User-Agent" => "Mozilla\t5.0"}
        HTTP::Client.get server.uri("/success"), headers: headers

        logs.check(:info, "")
        logs.entry.data[:user_agent].to_s.should eq("Mozilla 5.0")
      end
    end
  end

  it "truncates long User-Agent" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        headers = HTTP::Headers{"User-Agent" => "Mozilla/" + "a" * 600}
        HTTP::Client.get server.uri("/success"), headers: headers

        logs.check(:info, "")
        logs.entry.data[:user_agent].to_s.size.should be <= 512
      end
    end
  end

  it "sanitizes Referer" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        headers = HTTP::Headers{"Referer" => "https://example.com/\tpage"}
        HTTP::Client.get server.uri("/success"), headers: headers

        logs.check(:info, "")
        logs.entry.data[:referer].to_s.should eq("https://example.com/ page")
      end
    end
  end

  it "truncates long Referer" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        headers = HTTP::Headers{"Referer" => "https://example.com/" + "a" * 600}
        HTTP::Client.get server.uri("/success"), headers: headers

        logs.check(:info, "")
        logs.entry.data[:referer].to_s.size.should be <= 512
      end
    end
  end

  it "strips potentially sensitive data from Referer" do
    Log.capture(AppServer.log.source) do |logs|
      AppServer.new.listen do |server|
        headers = HTTP::Headers.new

        headers["Referer"] = "http://user:pass@example.com/path\
          ?query=1&secret=token#fragment"

        HTTP::Client.get server.uri("/success"), headers: headers
        logs.check(:info, "")
        logs.entry.data[:referer].to_s.should eq("http://example.com/path")
      end
    end
  end
end
