#! ruby
# coding: utf-8


require 'date'
require 'uri'
require_relative 'module/backend'
require_relative 'module/request'
require_relative 'module/shaleia'
require_relative 'module/utilities'


class ShaleiaInterface < BackendBase

  def switch
    case @command
    when "search"
      search
    when "request"
      request
    when "download"
      download
    when "update"
      update
    when "save_history"
      save_history
    when "fetch_twitter"
      fetch_twitter
    when "fetch_discord"
      fetch_discord
    when "fetch_twitter_example"
      fetch_twitter_example
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
    result["hitSize"] = 0
    unless search.empty?
      hit_names[page * 30, 30].each do |name|
        result["words"] << ShaleiaUtilities.parse(name, whole_data[name], version)
      end
      suggested_names.each do |explanation, name|
        result["suggestions"] << {"explanation" => explanation, "name" => name}
      end
      result["hitSize"] = hit_names.size
    end
    respond(result)
  end

  def request
    content = self["content"]
    requests = content.split("\n").map{|s| s.strip}.reject{|s| s.empty?}
    RequestUtilities.add(requests)
    result = {}
    result["requests"] = requests
    result["size"] = requests.size
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

  def update
    version = self["version"]&.to_i || 0
    size = ShaleiaUtilities.update(version)
    result = {}
    result["version"] = version
    result["size"] = size
    respond(result)
  end

  def save_history
    size = ShaleiaUtilities.save_history(0)
    result = {}
    result["size"] = size
    respond(result)
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
      equivalent_string = equivalent.names.join(", ").strip
      equivalent_string.gsub!(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
      next "〈#{equivalent.category}〉#{equivalent_string}"
    end
    output << equivalent_strings.join(" ")
    meaning_content = word.contents.find{|s| s.type == "語義"}
    if meaning_content
      meaning_text = meaning_content.text.strip
      meaning_text.gsub!(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
      if meaning_text != "?"
        output << " ❖ " + meaning_text
      end
    end
    output.gsub!(/&#x([0-9A-Fa-f]+);/){$1.to_i(16).chr}
    output << " "
    output << "http://ziphil.com/conlang/database/1.html?search=#{URI.encode(name)}&mode=search&type=0&agree=0"
    respond(output, :text)
  end

  def fetch_discord
    whole_data = ShaleiaUtilities.fetch_whole_data(0)
    excluded_names = ShaleiaUtilities.fetch_excluded_names
    if self["name"] != ""
      name, data = whole_data.find{|s, t| s == self["name"]}
    else
      candidates = whole_data.reject do |name, data|
        next excluded_names.include?(name) || name.start_with?("META") || name.start_with?("$")
      end
      name, data = candidates.to_a.sample
    end
    if name && data
      word = ShaleiaUtilities.parse(name, data, 0, true)
      output = {}
      embed = {}
      embed["title"] = word.name.gsub(/\~/, "")
      equivalent_strings = word.equivalents.map do |equivalent|
        equivalent_string = equivalent.names.join(", ").strip
        equivalent_string.gsub!(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
        equivalent_string.gsub!(/&#x([0-9A-Fa-f]+);/){$1.to_i(16).chr}
        next "**❬#{equivalent.category}❭** #{equivalent_string}"
      end
      embed["description"] = equivalent_strings.join("\n")
      embed["fields"] = []
      embed["fields"] << {"name" => "品詞", "value" => "❬#{word.sort}❭", "inline" => true}
      embed["fields"] << {"name" => "発音", "value" => "/#{word.pronunciation}/", "inline" => true}
      embed["fields"] << {"name" => "造語日", "value" => "ᴴ#{word.date.to_s}", "inline" => true}
      content_fields = word.contents.map do |content|
        content_text = content.text.strip
        content_text.gsub!(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
        content_text.gsub!(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
        content_text.gsub!(/&#x([0-9A-Fa-f]+);/){$1.to_i(16).chr}
        next {"name" => content.type, "value" => content_text}
      end
      embed["fields"].push(*content_fields)
      embed["url"] = "http://ziphil.com/conlang/database/1.html?search=#{URI.encode(name)}&mode=search&type=0&agree=0"
      embed["color"] = 0xFFAB33
      output["embeds"] = [embed]
      respond(output)
    else
      output = {}
      respond(output)
    end
  end

  def fetch_twitter_example
    whole_data = ShaleiaUtilities.fetch_whole_data(0)
    excluded_names = ShaleiaUtilities.fetch_excluded_names
    candidates = whole_data.map do |name, data|
      result = []
      unless excluded_names.include?(name)
        word = ShaleiaUtilities.parse(name, data, 0, true)
        example_contents = word.contents.select{|s| s.type == "example"}
        example_contents.each do |content|
          result << [name, content]
        end
      end
      next result
    end
    candidates.flatten!(1)
    name, content = candidates.sample
    output = ""
    name = name.gsub(/\~/, "")
    shaleian = content.shaleian.gsub(/\{(.+?)\}|\[(.+?)\]/){$1 || $2}.strip
    japanese = content.japanese.strip
    output << shaleian + " ► " + japanese
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
    output["message"] = whole_data.size.to_s
    respond(output)
  end

end


ShaleiaInterface.new(nil, CGI.new).run