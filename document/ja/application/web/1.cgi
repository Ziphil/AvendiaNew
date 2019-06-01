#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require 'date'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class WeblioSaver

  def initialize(cgi)
    @cgi = cgi
  end

  def prepare
    if @cgi.multipart?
      @command = (!@cgi.params["mode"].empty?) ? @cgi.params["mode"][0].read : ""
      @name = (!@cgi.params["name"].empty?) ? @cgi.params["name"][0].read : ""
      @content = (!@cgi.params["content"].empty?) ? @cgi.params["content"][0].read : ""
    else
      @command = @cgi["mode"]
      @name = @cgi["name"]
      @content = @cgi["content"]
    end
  end

  def run
    prepare
    case @command
    when "get"
      get
    when "save"
      save
    end
  rescue => exception
    error(exception.message.encode("utf-8") + "\n  " + exception.backtrace.join("\n  ").encode("utf-8"))
  end

  def get
    path = "../../file/weblio/" + @name + ".txt"
    if File.exist?(path)
      result = File.read(path)
    else 
      result = "No data"
    end
    @cgi.out("text/plain") do
      next result
    end
  end

  def save
    path = "../../file/weblio/" + @name + ".txt"
    File.write(path, @content)
    @cgi.out("text/plain") do
      next "Done"
    end
  end

  def error(message)
    @cgi.out("text/plain") do
      next message
    end
  end

end


WeblioSaver.new(CGI.new).run