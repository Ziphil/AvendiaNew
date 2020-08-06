#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require_relative '../../program/module/1'
require_relative '../../program/module/2'
require_relative '../../program/module/3'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class RequestManager < CustomBase

  def prepare
    @mode = @cgi["mode"]
    @content = @cgi["content"]
    @size = @cgi["size"].to_i
  end

  def switch
    case @mode
    when "request", "依頼"
      request
    when "finish"
      finish
    else
      default
    end
  end

  def default
    header = Source.header(@content)
    @cgi.out{Source.whole(header)}
  end

  def request
    requests = @content.split("\n").map{|s| s.strip}.reject{|s| s.empty?}
    option = {"status" => "REDIRECT", "location" => "6.cgi?mode=finish&size=#{requests.size}"}
    RequestUtilities.add(requests)
    @cgi.out(option){""}
  end

  def finish
    html = ""
    html << "<h1>依頼完了</h1>\n"
    html << "<p>\n"
    html << "造語依頼が完了しました (#{@size} 件)。\n"
    html << "ご協力ありがとうございます。\n"
    html << "</p>\n"
    header = Source.header
    @cgi.out{Source.whole(header, html)}
  end

end


module Source

  module_function

  def header(content = "")
    html = ""
    html << "<h1>造語依頼フォーム</h1>\n"
    html << "<p>\n"
    html << "造語依頼したい単語を、 1 行に 1 単語になるよう改行で区切って入力してください。\n"
    html << "同時に何単語でも依頼することができます。\n"
    html << "</p>\n"
    html << "<form action=\"6.cgi\" method=\"post\">\n"
    html << "<textarea class=\"normal\" name=\"content\" cols=\"50\" rows=\"6\">#{content.html_escape}</textarea><br>\n"
    html << "<input type=\"submit\" name=\"mode\" value=\"依頼\"></input>\n"
    html << "</form>\n"
    return html
  end

  def whole(header, main = "", footer = "")
    html = File.read("6.html")
    html.gsub!(/<special>.*?<\/special>|<special\/>/){header + main + footer}
    return html
  end

end


RequestManager.new(nil, CGI.new, Source).run