# coding: utf-8


require 'cgi'
require 'json'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class BackendBase

  def initialize(body, cgi)
    @body = body
    @cgi = cgi
    @responded = false
  end

  def run
    begin
      prepare
      switch
      unless @responded
        message = "noop"
        respond_error(message, "BAD_REQUEST")
      end
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
    @responded = true
  end

  def respond_download(file, name)
    option = {}
    option["status"] = "OK"
    option["type"] = "application/oct-stream"
    option["Content-Disposition"] = "download;filename=#{name}"
    @cgi.out(option){file.read}
    @responded = true
  end

  def respond_error(message, status = nil)
    option, output = {}, {}
    option["status"] = status || "SERVER_ERROR"
    option["type"] = "application/json"
    output["error"] = "error"
    output["message"] = message
    @cgi.out(option){JSON.generate(output)}
  end

  def body
    return @body
  end

  def [](name)
    if @cgi.multipart?
      if !@cgi.params[name].empty?
        return @cgi.params[name][0].read
      else
        return nil
      end
    else
      if @cgi[name]
        return @cgi[name]
      else
        return nil
      end
    end
  end

  def params(name)
    return @cgi.params[name]
  end

end
