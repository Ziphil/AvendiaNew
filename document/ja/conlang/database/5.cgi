#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require_relative '../../program/module/1'
require_relative '../../program/module/3'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class WholeSearcher < CustomBase

  def prepare
    @mode = @cgi["mode"]
    @search = @cgi["search"]
    @type = @cgi["type"].to_i
    @page = @cgi["page"].to_i
  end

  def switch
    case @mode
    when "search", "検索"
      search
    else
      default
    end
  end

  def default
    header = Source.header
    @cgi.out{Source.whole(header)}
  end

  def search
    paths = SearchUtilities.paths
    search_data = Hash.new{|h, k| h[k] = []}
    paths.each do |path|
      data = File.read(path)
      case @type
      when 0
        data.scan(/(?:<p>(.+?)<\/p>|<td>(.+?)<\/td>|<li>(.+?)<\/li>)/m) do |matches|
          match = matches.join
          match.each_line do |line|
            line = line.gsub(/<.+?>/, "")
            if line =~ /#{@search}/u
              search_data[path] << line.gsub(/#{@search}/){"%%%#{$&}%%%"}.html_escape.gsub(/%%%(.*?)%%%/){"<span class=\"match\">#{$1}</span>"}.strip
            end
          end
        end
      when 1
        data.scan(/<span class\=\"sans\">(.+?)<\/span>/) do |matches|
          match = matches[0].gsub(/<.+?>/, "")
          if match =~ /#{@search}/
            search_data[path] << match.gsub(/#{@search}/){"%%%#{$&}%%%"}.html_escape.gsub(/%%%(.*?)%%%/){"<span class=\"match\">#{$1}</span>"}.strip
          end
        end
      end
    end
    size = search_data.size
    html = ""
    html << "<h1>検索結果</h1>\n"
    search_data = search_data.sort_by do |path, _|
      new_path = path.gsub("../../", "").gsub(/\..+$/, "")
      new_path = new_path.split("/").reject{|s| s == "index"}.map{|s| (s.match(/^\d/)) ? s.to_i : s}
      next new_path
    end
    search_data[@page * 15, 15].each do |path, matches|
      new_path = path.gsub("../../", "")
      new_path = new_path.split("/").map{|s| (s =~ /\d/) ? s.to_i : s.gsub("index.html", "*")[0..2].capitalize}.join("-")
      new_path.gsub!(/\-(\*)$/){" *"}
      new_path.gsub!(/\-(\d+)$/){" ##{$1}"}
      html << "<div class=\"head\"><a href=\"#{path}\">#{new_path}</a></div>\n"
      html << "<div class=\"result-wrapper\">\n"
      html << "<div class=\"border\"></div>\n"
      html << "<div class=\"result\">\n"
      html << "<ul>\n"
      matches.each do |match|
        html << "<li>"
        html << match
        html << "</li>"
      end
      html << "</ul>\n"
      html << "</div>\n"
      html << "</div>\n"
    end
    html << "<div class=\"number\">\n"
    if @page > 0
      html << "<a class=\"left-arrow\" href=\"5.cgi?search=#{@search.url_escape}&mode=search&type=#{@type}&page=#{@page - 1}\"></a>"
    else
      html << "<span class=\"left-arrow invalid\"></span>"
    end
    html << "<div class=\"fraction\">"
    html << "<div class=\"page\">#{[@page * 15 + 1, size].min} ～ #{[@page * 15 + 15, size].min}</div>"
    html << "<div class=\"total\">#{size}</div>"
    html << "</div>"
    if @page * 15 + 15 < size
      html << "<a class=\"right-arrow\" href=\"5.cgi?search=#{@search.url_escape}&mode=search&type=#{@type}&page=#{@page + 1}\"></a>"
    else
      html << "<span class=\"right-arrow invalid\"></span>"
    end
    html << "</div>\n\n"
    header = Source.header(@search, @type)
    @cgi.out{Source.whole(header, html)}
  end

end


module Source

  module_function

  def header(search = "", type = 0)
    html = ""
    html << "<h1>検索フォーム</h1>\n"
    html << "<form action=\"5.cgi\" name=\"form\">\n"
    html << "<input type=\"text\" name=\"search\" value=\"#{search.html_escape}\"></input>　"
    html << "<input type=\"submit\" name=\"mode\" value=\"検索\"></input><br>\n"
    html << "<input type=\"radio\" name=\"type\" value=\"0\" id=\"radio-type-0\"#{(type == 0) ? " checked" : ""}></input>"
    html << "<label for=\"radio-type-0\">全体</label>　"
    html << "<input type=\"radio\" name=\"type\" value=\"1\" id=\"radio-type-1\"#{(type == 1) ? " checked" : ""}></input>"
    html << "<label for=\"radio-type-1\">シャレイア語</label><br>\n"
    html << "</form>\n"
    return html
  end

  def whole(header, main = "", footer = "")
    html = File.read("5.html")
    html.gsub!(/<special>.*?<\/special>|<special\/>/){header + main + footer}
    return html
  end

end


module SearchUtilities

  module_function

  def paths
    dirs = ["../.."]
    paths = []
    dirs.each do |dir|
      entries = Dir.entries(dir)
      entries.each do |entry|
        if /\.html/ =~ entry
          paths << dir + "/" + entry
        end
        unless /\./ =~ entry
          dirs << dir + "/" + entry
        end
      end
    end
    return paths
  end

end


WholeSearcher.new(nil, CGI.new, Source).run