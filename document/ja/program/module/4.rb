# coding: utf-8


require 'cgi'
require 'json'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class BackendBase

  def initialize(body, cgi)
    @body = body
    @cgi = cgi
  end

  def run
    begin
      prepare
      switch
    rescue => exception
      message = exception.message.encode("utf-8") + "\n  " + exception.backtrace.join("\n  ").encode("utf-8")
      respond_error(message)
    end
  end

  def prepare
    @command = self["mode"]
  end

  def switch
  end

  def respond(output, type = :json)
    option = {}
    option["status"] = "OK"
    case type
    when :json
      option["type"] = "application/json"
      @cgi.out(option){JSON.generate(output)}
    when :text
      option["type"] = "text/plain"
      @cgi.out(option){output.to_s}
    end
  end

  def respond_error(message)
    option, output = {}, {}
    option["status"] = "OK"
    option["type"] = "application/json"
    output["error"] = "error"
    output["message"] = message
    @cgi.out(option){JSON.generate(output)}
  end

  private

  def body
    return @body
  end

  def [](name, default = nil)
    if @cgi.multipart?
      if !@cgi.params[name].empty?
        return @cgi.params[name][0].read
      else
        return default
      end
    else
      if @cgi[name]
        return @cgi[name]
      else
        return default
      end
    end
  end

end
