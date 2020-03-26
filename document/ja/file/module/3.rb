#!/usr/bin/ruby
# coding: utf-8


class CustomBase

  def initialize(body, cgi, source_class = nil)
    @body = body
    @cgi = cgi
    @source_class = source_class
  end

  def run
    begin
      prepare
      switch
    rescue => exception
      message = exception.message.encode("utf-8") + "\n  " + exception.backtrace.join("\n  ").encode("utf-8")
      error(message)
    end
  end

  def prepare
  end

  def switch
  end

  def error(message)
    if @source_class
      html = ""
      html << "<h1>エラー</h1>\n"
      html << "<p>\n"
      html << "エラーが発生しました。\n"
      html << "</p>\n"
      html << "<div class=\"code-wrapper\"><div class=\"code-inner-wrapper\"><table class=\"code\">\n"
      message.gsub(/^(\s*)(.+)\.(rb|cgi):/){"#{$1}****.#{$3}:"}.each_line do |line|
        html << "<tr><td>"
        html << line.rstrip.html_escape
        html << "</td></tr>\b"
      end
      html << "</table></div></div>\n"
      html.gsub!("\b", "")
      header = @source_class.header
      @cgi.out{@source_class.whole(header, html)}
    else
      output = ""
      message.gsub(/^(\s*)(.+)\.(rb|cgi):/){"#{$1}****.#{$3}:"}.each_line do |line|
        output << line.rstrip
        output << "\n"
      end
      @cgi.out("text/plain"){output}
    end
  end

end