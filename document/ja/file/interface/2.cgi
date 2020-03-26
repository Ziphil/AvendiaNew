#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require 'date'
require_relative '../../file/module/3'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class WeblioSaver < CustomBase

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

  def switch
    case @command
    when "get"
      get
    when "get_number"
      get_number
    when "save"
      save
    end
  end

  def get
    output = "No data"
    if File.exist?("../../file/weblio/#{@number}.txt")
      output = File.read("../../file/weblio/#{@number}.txt")
    end
    @cgi.out("text/plain"){output}
  end

  def get_number
    number = 1
    if File.exist?("../../file/weblio/meta.txt")
      number = File.read("../../file/weblio/meta.txt").to_i + 1
    end
    @cgi.out("text/plain"){number.to_s}
  end

  def save
    File.write("../../file/weblio/#{@number}.txt", @content)
    File.write("../../file/weblio/meta.txt", @number)
    @cgi.out("text/plain"){"Done"}
  end

end


WeblioSaver.new(nil, CGI.new).run