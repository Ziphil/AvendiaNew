#! ruby
# coding: utf-8


require 'date'
require_relative 'module/backend'


class WeblioSaver < BackendBase

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
    number = self["number"].to_i
    output = "No data"
    if File.exist?("../../file/weblio/#{number}.txt")
      output = File.read("../../file/weblio/#{number}.txt")
    end
    respond(output, :text)
  end

  def get_number
    number = 1
    if File.exist?("../../file/weblio/meta.txt")
      number = File.read("../../file/weblio/meta.txt").to_i + 1
    end
    respond(number, :text)
  end

  def save
    number = self["number"].to_i
    content = self["content"]
    File.write("../../file/weblio/#{number}.txt", content)
    File.write("../../file/weblio/meta.txt", number)
    respond("Done", :text)
  end

end


WeblioSaver.new(nil, CGI.new).run