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
      @number = (!@cgi.params["number"].empty?) ? @cgi.params["number"][0].read : ""
      @content = (!@cgi.params["content"].empty?) ? @cgi.params["content"][0].read : ""
    else
      @command = @cgi["mode"]
      @number = @cgi["number"]
      @content = @cgi["content"]
    end
  end

  def run
    prepare
    case @command
    when "get"
      get
    when "get_number"
      get_number
    when "save"
      save
    end
  rescue => exception
    error(exception.message.encode("utf-8") + "\n  " + exception.backtrace.join("\n  ").encode("utf-8"))
  end

  def get
    output = "No data"
    if File.exist?("../../file/weblio/#{@number}.txt")
      output = File.read("../../file/weblio/#{@number}.txt")
    end
    @cgi.out("text/plain") do
      next output
    end
  end

  def get_number
    number = 1
    if File.exist?("../../file/weblio/meta.txt")
      number = File.read("../../file/weblio/meta.txt").to_i + 1
    end
    @cgi.out("text/plain") do
      next number.to_s
    end
  end

  def save
    File.write("../../file/weblio/#{@number}.txt", @content)
    File.write("../../file/weblio/meta.txt", @number)
    @cgi.out("text/plain") do
      next "Done"
    end
  end

  def error(message)
    output = ""
    message.gsub(/^(\s*)(.+)\.(rb|cgi):/){"#{$1}****.#{$3}:"}.each_line do |line|
      output << line.rstrip
      output << "\n"
    end
    @cgi.out("text/plain") do
      next output
    end
  end

end


WeblioSaver.new(CGI.new).run