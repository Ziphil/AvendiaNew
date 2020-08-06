#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require 'uri'
require 'date'
require_relative '../../program/module/1'
require_relative '../../program/module/2'
require_relative '../../program/module/3'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class ShaleiaDictionary < CustomBase

  def prepare
    @command = @cgi["mode"]
    @search = @cgi["search"]
    @mode = @cgi["type"].to_i
    @type = @cgi["agree"].to_i
    @random = @cgi["random"].to_i
    @version = @cgi["version"].to_i
    @option = (!@cgi["option"].empty?) ? @cgi.params["option"].map{|s| s.to_i} : [0, 1, 2, 3, 4]
    @conversion = (!@cgi["conversion"].empty?) ? @cgi.params["conversion"].map{|s| s.to_i} : [0]
    @page = @cgi["page"].to_i
  end

  def switch
    case @command
    when "search", "検索"
      search
    when "fetch"
      fetch
    else
      default
    end
  end

  def default
    header = Source.header
    @cgi.out{Source.whole(header)}
  end

  def search
    whole_data = ShaleiaUtilities.fetch_whole_data(@version)
    excluded_names = ShaleiaUtilities.fetch_excluded_names
    hit_names, suggested_names = ShaleiaUtilities.search(@search, @mode, @type, @version)
    hit_names.reject!{|s| excluded_names.include?(s)}
    suggested_names.reject!{|_, s| excluded_names.include?(s)}
    hit_names.shuffle! if @random == 1
    size = hit_names.size
    option_string = "&version=#{@version}" + @option.map{|s| "&option=#{s}"}.join + @conversion.map{|s| "&conversion=#{s}"}.join
    html = ""
    html << "<h1>検索結果</h1>\n"
    unless suggested_names.empty?
      html << Source.suggested_word_html(suggested_names, option_string)
    end
    if hit_names.empty? && suggested_names.empty? && (@mode == 1 || @mode == 3) && @version == 0
      html << Source.request_html(@search)
    end
    hit_names[@page * 30, 30].each do |name|
      html << Source.word_html(name, whole_data[name], @version, @option, option_string)
    end
    html << "<div class=\"number\">\n"
    if @page > 0
      html << "<a class=\"left-arrow\" href=\"1.cgi?search=#{@search.url_escape}&mode=search&type=#{@mode}&agree=#{@type}&page=#{@page - 1}#{option_string}\"></a>"
    else
      html << "<span class=\"left-arrow invalid\"></span>"
    end
    html << "<div class=\"fraction\">"
    html << "<div class=\"page\">#{[@page * 30 + 1, size].min} ～ #{[@page * 30 + 30, size].min}</div>"
    html << "<div class=\"total\">#{size}</div>"
    html << "</div>"
    if @page * 30 + 30 < size
      html << "<a class=\"right-arrow\" href=\"1.cgi?search=#{@search.url_escape}&mode=search&type=#{@mode}&agree=#{@type}&page=#{@page + 1}#{option_string}\"></a>"
    else
      html << "<span class=\"right-arrow invalid\"></span>"
    end
    html << "</div>\n\n"
    header = Source.header(@search, @mode, @type, @version, @option, @conversion, @random)
    @cgi.out{Source.whole(header, html)}
  end

  def fetch
    output = ""
    begin
      case @mode
      when 0
        whole_data = ShaleiaUtilities.fetch_whole_data(0)
        excluded_names = ShaleiaUtilities.fetch_excluded_names
        candidates = whole_data.reject do |name, data|
          next excluded_names.include?(name) || name.start_with?("META") || name.start_with?("$")
        end
        name, data = candidates.to_a.sample
        output << Source.word_text(name, data)
      when 2
        whole_data = ShaleiaUtilities.fetch_whole_data(0)
        excluded_names = ShaleiaUtilities.fetch_excluded_names
        candidates = whole_data.map do |name, data|
          result = []
          unless excluded_names.include?(name)
            data.scan(/^S>\s*(.+)\s*→\s*(.+)/) do |sentence, translation|
              result << [name, sentence, translation]
            end
          end
          next result
        end
        candidates = candidates.inject([]){|s, t| s + t}
        name, sentence, translation = candidates.sample
        output << Source.example_text(name, sentence, translation)
      when 1
        whole_data = ShaleiaUtilities.fetch_whole_data_without_meta(0)
        output << whole_data.size.to_s
      when 3
        whole_data = ShaleiaUtilities.fetch_whole_data_without_meta(0)
        histories = ShaleiaUtilities.fetch_histories(0)
        hairia = ShaleiaTime.now_hairia - @type
        history = histories.fetch(hairia, nil)
        if history
          if whole_data.size > history
            output << (whole_data.size - history).to_s
          else
            output << "0"
          end
        else
          output << "?"
        end
      when 4
        version = @type
        whole_data = ShaleiaUtilities.fetch_whole_data_without_meta(version)
        output << "{\"schemaVersion\":1,\"color\":\"informational\",\"label\":\"words\",\"message\": \"#{whole_data.size}\"}"
      end
    rescue => exception
      output = ""
    end
    @cgi.out("text/plain"){output}
  end

end


module Source

  CAPTION_ALPHABETS = {"E" => "語源", "U" => "語法", "N" => "備考", "P" => "成句"}

  module_function

  def suggested_word_html(suggested_names, option_string)
    html = ""
    html << "<ul class=\"suggest\">\n"
    suggested_names.each do |explanation, name|
      html << "<li>#{explanation}"
      html << "<a href=\"1.cgi?search=#{name}&mode=search&type=0&agree=0#{option_string}\" class=\"sans\">#{name.gsub(/(\+|\~)/, "")}</a>"
      html << " ?</li>\n"
    end
    html << "</ul>\n"
    return html
  end

  def request_html(search)
    html = ""
    html << "<ul class=\"suggest\">\n"
    html << "<li>造語依頼すれば造語されるかもしれません <span class=\"japanese\">…</span> "
    html << "<a href=\"6.cgi?content=#{search.url_escape}\">造語依頼</a>"
    html << "</li>\n"
    html << "</ul>\n"
  end

  def word_html(name, data, version = 0, option = 0..4, option_string = "")
    html = ""
    has_content = false
    begin_equivalent, begin_example, begin_synonym = false, false, false
    old_name = name.clone
    name = name.gsub(/\~/, "")
    if ShaleiaStringUtilities.pronunciation(name) == "" || version != 0
      html << "<div class=\"head\">\n"
      html << "<span class=\"head-name\"><span class=\"sans\">#{name}</sans></span>\n"
    else
      html << "<div class=\"head\">\n"
      html << "<span class=\"head-name\"><span class=\"sans\">#{name}</span></span><span class=\"pronunciation\">/#{ShaleiaStringUtilities.pronunciation(name)}/</span>\n"
    end
    data.each_line do |line|
      line.gsub!(/^\=:(.*)$/, "")
      line.gsub!(/^\=\=:(.*)$/, "")
      line.gsub!(/\bH(\d+)/){"<span class=\"hairia\">#{$1}</span>"}
      line.gsub!(/\/(.+?)\//){"<i>#{$1}</i>"}
      line.gsub!(/\{(.+?)\}|\[(.+?)\]/) do
        match = $1 || $2
        link = !!$1
        next WordConverter.convert(match, "1.cgi", link, version, nil, option_string)
      end
      if match = line.match(/^\+\s*(\d+)\s*〈(.+)〉/)
        has_content = true
        html << "<span class=\"date\">#{match[1]}</span><span class=\"box\">#{match[2]}</span>\n"
        html << "</div>\n"
        html << "<div class=\"result-wrapper\">\n"
        html << "<div class=\"border\"></div>\n"
        html << "<div class=\"result\">\n"
      end
      if match = line.match(/^\=\s*〈(.+?)〉\s*(.+)/)
        unless begin_equivalent
          html << "<p class=\"equivalent\">"
          begin_equivalent = true
        end
        html << "<span class=\"box\">"
        html << match[1].gsub(/\:(.+)/){"<span class=\"addition\">#{$1}</span>"}
        html << "</span>"
        html << match[2].gsub(/\((.+?)\)\s*/){"<span class=\"small\">#{$1}</span>"}
        html << "<br>\n"
      end
      if option.include?(0) && match = line.match(/^M>\s*(.+)/)
        if begin_equivalent
          html << "</p>\n" 
          begin_equivalent = false
        end
        html << "<div class=\"explanation\"><div class=\"kind\">"
        html << "語義:"
        html << "</div>"
        html << "<div class=\"content\">"
        html << ShaleiaStringUtilities.convert_punctuation(match[1]).chomp
        html << "</div></div>\n"
      end
      if option.include?(1) && match = line.match(/^([^MSE])>\s*(.+)/)
        if CAPTION_ALPHABETS.key?(match[1])
          if begin_equivalent
            html << "</p>\n" 
            begin_equivalent = false
          end
          html << "<div class=\"explanation\"><div class=\"kind\">"
          html << CAPTION_ALPHABETS[match[1]] + ":"
          html << "</div>"
          html << "<div class=\"content\">"
          html << ShaleiaStringUtilities.convert_punctuation(match[2]).chomp
          html << "</div></div>\n"
        end
      end
      if option.include?(4) && match = line.match(/^E>\s*(.+)/)
        if begin_equivalent
          html << "</p>\n" 
          begin_equivalent = false
        end
        html << "<div class=\"explanation\"><div class=\"kind\">"
        html << CAPTION_ALPHABETS["E"] + ":"
        html << "</div>"
        html << "<div class=\"content\">"
        html << ShaleiaStringUtilities.convert_punctuation(match[1]).chomp
        html << "</div></div>\n"
      end
      if option.include?(2) && match = line.match(/^S>\s*(.+)\s*→\s*(.+)/)
        if begin_equivalent
          html << "</p>\n" 
          begin_equivalent = false
        end
        unless begin_example
          html << "<ul class=\"conlang\">"
          begin_example = true
        end
        html << "<li>#{match[1]}<ul><li>#{ShaleiaStringUtilities.convert_punctuation(match[2])}</li></ul></li>"
      end
      if option.include?(3) && match = line.match(/^\-\s*(?:〈(.+)〉)?\s*(.+)/)
        if begin_equivalent
          html << "</p>\n" 
          begin_equivalent = false
        end
        if begin_example
          html << "</ul>\n" 
          begin_example = false
        end
        unless begin_synonym
          html << "<p class=\"synonym\">"
          begin_synonym = true
        end
        html << match[2].gsub("*", "<span class=\"asterisk\">†</span>")
        html << "; "
      end
    end
    if begin_equivalent
      html << "</p>\n" 
    end
    if begin_example
      html << "</ul>\n" 
    end
    if begin_synonym
      html.gsub!(/;\s*$/, "")
      html << "</p>\n"
    end
    if has_content
      html << "</div>\n"
    end
    html << "</div>\n"
    return html
  end

  def word_text(name, data)
    text = ""
    name = name.gsub(/\~/, "")
    text << "#{name} /#{ShaleiaStringUtilities.pronunciation(name)}/ "
    equivalents = []
    meaning = nil
    data.each_line do |line|
      if match = line.match(/^\=\s*〈(.+?)〉\s*(.+)/)
        part = match[1]
        raw_equvalent = match[2].strip.gsub(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
        equivalents << "〈#{part}〉#{raw_equvalent}"
      elsif match = line.match(/^M>\s*(.+)/)
        raw_meaning = match[1].strip.gsub(/\/(.+?)\/|\{(.+?)\}|\[(.+?)\]/){$1 || $2 || $3}
        unless raw_meaning == "?"
          meaning = raw_meaning
        end
      end
    end
    text << equivalents.join(" ")
    text << " ❖ #{meaning}" if meaning
    text.gsub!(/&#x([0-9A-Fa-f]+);/){$1.to_i(16).chr}
    text << " "
    text << "http://ziphil.com/conlang/database/1.cgi?search=#{URI.encode(name)}&mode=search&type=0&agree=0"
    return text
  end

  def example_text(name, sentence, translation)
    text = ""
    name = name.gsub(/\~/, "")
    sentence = sentence.gsub(/\{(.+?)\}|\[(.+?)\]/){$1 || $2}.strip
    translation = translation.strip
    text << "#{sentence} ► #{translation}"
    text.gsub!(/&#x([0-9A-Fa-f]+);/){$1.to_i(16).chr}
    text << " "
    text << "http://ziphil.com/conlang/database/1.cgi?search=#{URI.encode(name)}&mode=search&type=0&agree=0"
    return text
  end

  def header(search = "", mode = 3, type = 0, version = 0, option = 0..4, conversion = [0], random = 0)
    html = ""
    html << "<h1>検索フォーム</h1>\n"
    html << "<form action=\"1.cgi\">\n"
    html << "<input type=\"text\" name=\"search\" value=\"#{search.html_escape}\" accesskey=\"q\"></input>　"
    html << "<input type=\"submit\" name=\"mode\" value=\"検索\"></input>"
    html << "<br>\n"
    html << "<input type=\"radio\" name=\"type\" value=\"3\" id=\"radio-type-3\"#{(mode == 3) ? " checked" : ""}></input>"
    html << "<label for=\"radio-type-3\">単語<span class=\"japanese\">＋</span>訳語</label>　"
    html << "<input type=\"radio\" name=\"type\" value=\"0\" id=\"radio-type-0\"#{(mode == 0) ? " checked" : ""}></input>"
    html << "<label for=\"radio-type-0\">単語</label>　"
    html << "<input type=\"radio\" name=\"type\" value=\"1\" id=\"radio-type-1\"#{(mode == 1) ? " checked" : ""}></input>"
    html << "<label for=\"radio-type-1\">訳語</label>　"
    html << "<input type=\"radio\" name=\"type\" value=\"2\" id=\"radio-type-2\"#{(mode == 2) ? " checked" : ""}></input>"
    html << "<label for=\"radio-type-2\">全文</label><br>\n"
    html << "<input type=\"radio\" name=\"agree\" value=\"0\" id=\"radio-agree-0\"#{(type == 0) ? " checked" : ""}></input>"
    html << "<label for=\"radio-agree-0\">完全一致</label>　"
    html << "<input type=\"radio\" name=\"agree\" value=\"1\" id=\"radio-agree-1\"#{(type == 1) ? " checked" : ""}></input>"
    html << "<label for=\"radio-agree-1\">部分一致</label>　"
    html << "<input type=\"radio\" name=\"agree\" value=\"2\" id=\"radio-agree-2\"#{(type == 2) ? " checked" : ""}></input>"
    html << "<label for=\"radio-agree-2\">最小対語</label><br>\n"
    html << "<input type=\"checkbox\" name=\"option\" value=\"0\" id=\"checkbox-option-0\"#{(option.include?(0)) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-option-0\">語釈</label>　"
    html << "<input type=\"checkbox\" name=\"option\" value=\"4\" id=\"checkbox-option-4\"#{(option.include?(4)) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-option-4\">語源</label>　"
    html << "<input type=\"checkbox\" name=\"option\" value=\"1\" id=\"checkbox-option-1\"#{(option.include?(1)) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-option-1\">語法</label>　"
    html << "<input type=\"checkbox\" name=\"option\" value=\"2\" id=\"checkbox-option-2\"#{(option.include?(2)) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-option-2\">例文</label>　"
    html << "<input type=\"checkbox\" name=\"option\" value=\"3\" id=\"checkbox-option-3\"#{(option.include?(3)) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-option-3\">関連語</label><br>\n"
    html << "<input type=\"radio\" name=\"version\" value=\"0\" id=\"radio-version-0\"#{(version == 0) ? " checked" : ""}></input>"
    html << "<label for=\"radio-version-0\">5 代 5 期</label>　"
    html << "<input type=\"radio\" name=\"version\" value=\"2\" id=\"radio-version-2\"#{(version == 2) ? " checked" : ""}></input>"
    html << "<label for=\"radio-version-2\">3 代 6 期</label>　"
    html << "<input type=\"radio\" name=\"version\" value=\"4\" id=\"radio-version-4\"#{(version == 4) ? " checked" : ""}></input>"
    html << "<label for=\"radio-version-4\">3 代 4 期</label>　"
    html << "<input type=\"radio\" name=\"version\" value=\"3\" id=\"radio-version-3\"#{(version == 3) ? " checked" : ""}></input>"
    html << "<label for=\"radio-version-3\">2 代 7 期</label>　"
    html << "<input type=\"radio\" name=\"version\" value=\"1\" id=\"radio-version-1\"#{(version == 1) ? " checked" : ""}></input>"
    html << "<label for=\"radio-version-1\">1 代 2 期</label><br>\n"
    html << "<input type=\"checkbox\" name=\"conversion\" value=\"0\" id=\"checkbox-conversion-0\"#{(conversion.include?(0)) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-conversion-0\">正書法変換</label>　"
    html << "<input type=\"checkbox\" name=\"random\" value=\"1\" id=\"checkbox-random-1\"#{(random == 1) ? " checked" : ""}></input>"
    html << "<label for=\"checkbox-random-1\">結果シャッフル</label><br>\n"
    html << "</form>\n"
    return html
  end

  def whole(header, main = "", footer = "")
    html = File.read("1.html")
    html.gsub!(/<special>.*?<\/special>|<special\/>/){header + main + footer}
    return html
  end

end


ShaleiaDictionary.new(nil, CGI.new, Source).run