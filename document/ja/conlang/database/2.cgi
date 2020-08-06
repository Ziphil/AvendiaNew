#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require 'open-uri'
require_relative '../../program/module/1'
require_relative '../../program/module/2'
require_relative '../../program/module/3'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class ShaleiaManager < CustomBase

  PASSWORD = File.read("../../file/dictionary/meta/other/password.txt")

  def prepare
    if @cgi.multipart?
      @command = (!@cgi.params["mode"].empty?) ? @cgi.params["mode"][0].read : ""
      @version = (!@cgi.params["version"].empty?) ? @cgi.params["version"][0].read.to_i : 0
      @index = (!@cgi.params["index"].empty?) ? @cgi.params["index"][0].read.to_i : 0
      @password = (!@cgi.params["password"].empty?) ? @cgi.params["password"][0].read : ""
      @file = (!@cgi.params["file"].empty?) ? @cgi.params["file"][0] : nil
    else
      @command = @cgi["mode"]
      @version = @cgi["version"].to_i
      @index = @cgi["index"].to_i
      @password = @cgi["password"]
      @file = nil
    end
    unless @password == PASSWORD
      raise RuntimeError.new("not authorized")
    end
  end

  def switch
    case @command
    when "update"
      update
    when "delete_request"
      delete_request
    when "delete_logs"
      delete_logs
    when "save_history"
      save_history
    else
      default
    end
  end

  def default
    word_size = ShaleiaUtilities.fetch_names.size
    logs = ShaleiaUtilities.fetch_logs
    requests = RequestUtilities.fetch
    html = ""
    html << "<h1>辞書内部データ更新</h1>"
    html << "<form action=\"2.cgi\">"
    html << "<input type=\"submit\" value=\"更新\"></input>　(#{word_size} 語)"
    html << "<input type=\"hidden\" name=\"version\" value=\"0\"></input>"
    html << "<input type=\"hidden\" name=\"mode\" value=\"update\"></input>"
    html << "<input type=\"hidden\" name=\"password\" value=\"#{@password}\"></input>"
    html << "</form>"
    html << "<h1>造語依頼一覧</h1>\n"
    unless requests.empty?
      html << "<ol class=\"triple\">\n"
      requests.each_with_index do |request, i|
        html << "<li>#{request.html_escape} "
        if true
          html << "(<a href=\"2.cgi?mode=delete_request&index=#{i}&password=#{@password}\">削除</a>)"
        else
          html << "<form class=\"inline\">"
          html << "<input type=\"submit\" value=\"削除\"></input>"
          html << "<input type=\"hidden\" name=\"mode\" value=\"delete_request\"></input>"
          html << "<input type=\"hidden\" name=\"index\" value=\"#{i}\"></input>"
          html << "<input type=\"hidden\" name=\"password\" value=\"#{@password}\"></input>"
          html << "</form>"
        end
        html << "</li>\n"
      end
      html << "</ol>\n"
    end
    html << "<h1>検索履歴</h1>\n"
    unless logs.empty?
      html << "<ul class=\"double\">\n"
      logs.reverse_each do |log|
        html << "<li>#{log.html_escape}</li>\n"
      end
      html << "</ul>\n"
    end
    html << "<form action=\"2.cgi\">"
    html << "<input type=\"submit\" value=\"全削除\"></input>"
    html << "<input type=\"hidden\" name=\"mode\" value=\"delete_logs\"></input>"
    html << "<input type=\"hidden\" name=\"password\" value=\"#{@password}\"></input>"
    html << "</form>"
    header = Source.header
    @cgi.out{Source.whole(header, html)}
  end

  def update
    ShaleiaUtilities.update(@version)
    option = {"status" => "REDIRECT", "location" => "2.cgi?password=#{@password}"}
    @cgi.out(option){""}
  end

  def delete_request
    RequestUtilities.delete_at(@index)
    option = {"status" => "REDIRECT", "location" => "2.cgi?password=#{@password}"}
    @cgi.out(option){""}
  end

  def delete_logs
    ShaleiaUtilities.delete_logs
    option = {"status" => "REDIRECT", "location" => "2.cgi?password=#{@password}"}
    @cgi.out(option){""}
  end

  def save_history
    ShaleiaUtilities.save_history(0)
    option = {"status" => "REDIRECT", "location" => "2.cgi?password=#{@password}"}
    @cgi.out(option){""}
  end

end


module Source
  
  module_function

  def header
    html = ""
    return html
  end

  def whole(header, main = "", footer = "")
    html = File.read("2.html")
    html.gsub!(/<special>.*?<\/special>|<special\/>/){header + main + footer}
    return html
  end

end


ShaleiaManager.new(nil, CGI.new, Source).run