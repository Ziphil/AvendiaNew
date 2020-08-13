#!/usr/bin/ruby
# coding: utf-8


require 'date'
require 'uri'
require_relative '../../program/module/1'
require_relative '../../program/module/4'


class HomepageInterface < BackendBase

  def switch
    case @command
    when "search"
      search
    end
  end

  def search
    search = self["search"]
    mode = self["type"].to_i
    page = self["page"].to_i
    paths = SearchUtilities.paths
    search_data = Hash.new{|h, k| h[k] = []}
    paths.each do |path|
      data = File.read(path)
      case mode
      when 0
        data.scan(/(?:<p>(.+?)<\/p>|<td>(.+?)<\/td>|<li>(.+?)<\/li>)/m) do |matches|
          match = matches.join
          match.each_line do |line|
            line = line.gsub(/<.+?>/, "").strip
            if line_match = line.match(/#{search}/u)
              first, last = line_match.offset(0)
              search_data[path] << [line[0...first], line[first...last], line[last..-1]]
            end
          end
        end
      when 1
        data.scan(/<span class\=\"sans\">(.+?)<\/span>/) do |matches|
          match = matches[0].gsub(/<.+?>/, "")
          if match_match = match.match(/#{search}/u)
            first, last = match_match.offset(0)
            search_data[path] << [match[0...first], match[first...last], match[last..-1]]
          end
        end
      end
    end
    search_data = search_data.sort_by do |path, _|
      new_path = path.gsub("../../", "").gsub(/\..+$/, "")
      new_path = new_path.split("/").reject{|s| s == "index"}.map{|s| (s.match(/^\d/)) ? s.to_i : s}
      next new_path
    end
    result = {}
    result["matches"] = []
    result["hitSize"] = search_data.size
    search_data[page * 15, 15].each do |path, splits|
      name = path.gsub("../../", "")
      name = name.split("/").map{|s| (s =~ /\d/) ? s.to_i : s.gsub("index.html", "*")[0..2].capitalize}.join("/")
      name.gsub!(/\/(\*)$/){" @"}
      name.gsub!(/\/(\d+)$/){" ##{$1}"}
      match = {}
      match["name"] = name
      match["path"] = path
      match["splits"] = splits
      result["matches"] << match
    end
    respond(result)
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


HomepageInterface.new(nil, CGI.new).run