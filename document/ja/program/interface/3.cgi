#!/usr/bin/ruby
# coding: utf-8


require 'date'
require 'uri'
require_relative '../../program/module/1'
require_relative '../../program/module/4'


class ShaleiaInterface < BackendBase

  def switch
    case @command
    when "search"
      search
    when "download"
      download
    when "fetch_twitter"
      fetch_twitter
    when "fetch_word_size"
      fetch_word_size
    when "fetch_progress"
      fetch_progress
    when "fetch_badge"
      fetch_badge
    end
  end

  def search
    search = self["search"]
    mode = self["type"].to_i
    type = self["agree"].to_i
    page = self["page"].to_i
    random = self["random"].to_i
    version = self["version"].to_i
    whole_data = ShaleiaUtilities.fetch_whole_data(version)
    excluded_names = ShaleiaUtilities.fetch_excluded_names
    hit_names, suggested_names = ShaleiaUtilities.search(search, mode, type, version)
    hit_names.reject!{|s| excluded_names.include?(s)}
    suggested_names.reject!{|_, s| excluded_names.include?(s)}
    hit_names.shuffle! if random == 1
    result = {}
    result["words"] = []
    result["suggestions"] = []
    hit_names[page * 30, 30].each do |name|
      result["words"] << ShaleiaUtilities.parse(name, whole_data[name], version)
    end
    suggested_names.each do |explanation, name|
      result["suggestions"] << {"explanation" => explanation, "name" => name}
    end
    respond(result)
  end

  def download
    type = self["type"]
    case type
    when "pdic"
      file = File.new("../../file/dictionary/data/personal/1.dic")
      name = "shaleia.dic"
    when "otm"
      file = File.new("../../file/dictionary/data/slime/1.json")
      name = "shaleia.json"
    when "zpdic"
      file = File.new("../../file/dictionary/data/shaleia/1.xdc")
      name = "shaleia.xdc"
    end
    respond_download(file, name)
  end

  def fetch_twitter
    whole_data = ShaleiaUtilities.fetch_whole_data(0)
    excluded_names = ShaleiaUtilities.fetch_excluded_names
    candidates = whole_data.reject do |name, data|
      next excluded_names.include?(name) || name.start_with?("META") || name.start_with?("$")
    end
    name, data = candidates.to_a.sample
    word = ShaleiaUtilities.parse(name, data, 0, true)
    output = ""
    output << word.name.gsub(/\~/, "")
    output << " /" + word.pronunciation + "/ "
    equivalent_strings = word.equivalents.map do |equivalent|
      equivalent_string = equivalent.names.join(", ").gsub(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
      next "〈#{equivalent.category}〉#{equivalent_string}"
    end
    meaning_content = word.contents.find{|s| s.type == "meaning"}
    output << equivalent_strings.join(" ")
    output << " ❖ " + meaning_content.text if meaning_content
    output.gsub!(/&#x([0-9A-Fa-f]+);/){$1.to_i(16).chr}
    output << " "
    output << "http://ziphil.com/conlang/database/1.cgi?search=#{URI.encode(name)}&mode=search&type=0&agree=0"
    respond(output, :text)
  end

  def fetch_word_size
    version = self["version"].to_i
    whole_data = ShaleiaUtilities.fetch_whole_data_without_meta(version)
    output = whole_data.size
    respond(output, :text)
  end

  def fetch_progress
    version = self["version"].to_i
    hairia = ShaleiaTime.now_hairia - self["duration"].to_i
    whole_data = ShaleiaUtilities.fetch_whole_data_without_meta(version)
    histories = ShaleiaUtilities.fetch_histories(version)
    history = histories.fetch(hairia, nil)
    if history
      if whole_data.size > history
        output = whole_data.size - history
      else
        output = 0
      end
    else
      output = "?"
    end
    respond(output, :text)
  end

  def fetch_badge
    version = self["version"].to_i
    whole_data = ShaleiaUtilities.fetch_whole_data_without_meta(version)
    output = {}
    output["schemaVersion"] = 1
    output["color"] = "informational"
    output["label"] = "words"
    output["message"] = whole_data.size
    respond(output)
  end

end


ShaleiaInterface.new(nil, CGI.new).run