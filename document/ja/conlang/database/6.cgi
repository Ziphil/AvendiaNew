#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require_relative '../../file/module/1'
require_relative '../../file/module/2'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class RequestManager

  def initialize(cgi)
    @cgi = cgi
  end

  def prepare
    @mode = @cgi["mode"]
    @content = @cgi["content"]
    @size = @cgi["size"].to_i
  end

  def run
    prepare
    case @mode
    when "request", "依頼"
      request
    when "finish"
      finish
    else
      default
    end
  rescue => exception
    error(exception.message + "\n  " + exception.backtrace.join("\n  "))
  end

  def default
    header = Source.header(@content)
    @cgi.out do 
      next Source.whole(header)
    end
  end

  def finish
    html = ""
    html << "<h1>依頼完了</h1>\n"
    html << "<p>\n"
    html << "造語依頼が完了しました (#{@size} 件)。\n"
    html << "ご協力ありがとうございます。\n"
    html << "</p>\n"
    header = Source.header
    @cgi.out do
      next Source.whole(header, html)
    end
  end

  def request
    requests = @content.split("\n").map{|s| s.strip}.reject{|s| s.empty?}
    RequestUtilities.add(requests)
    @cgi.out({"status" => "REDIRECT", "location" => "6.cgi?mode=finish&size=#{requests.size}"}) do 
      next ""
    end
  end

  def error(message)
    html = ""
    html << "<h1>エラー</h1>\n"
    html << "<p>\n"
    html << "エラーが発生しました。\n"
    html << "</p>\n"
    html << "<table class=\"code\">\n"
    message.gsub(/^(\s*)(.+)\.(rb|cgi):/){"#{$1}****.#{$3}:"}.each_line do |line|
      html << "<tr><td>"
      html << line.rstrip.html_escape
      html << "</td></tr>\b"
    end
    html << "</table>\n"
    html.gsub!("\b", "")
    header = Source.header
    @cgi.out do
      next Source.whole(header, html)
    end
  end

end


module Source;extend self

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


RequestManager.new(CGI.new).run