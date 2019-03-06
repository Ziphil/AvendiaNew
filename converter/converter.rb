# coding: utf-8


require 'pp'
require 'fileutils'
require 'delegate'
require 'net/ftp'
require 'rexml/document'
include REXML

BASE_PATH = File.expand_path("..", File.dirname($0)).encode("utf-8")

Kernel.load(BASE_PATH + "/converter/parser.rb")
Kernel.load(BASE_PATH + "/converter/utility.rb")
Kernel.load(BASE_PATH + "/document/lbs/file/module/2.rb")
Encoding.default_external = "UTF-8"
$stdout.sync = true


class PageConverter

  attr_reader :configs

  def initialize(document)
    @document = document
    @configs = {}
    @templates = {}
    @functions = {}
    @default_element_template = lambda{|s| ""}
    @default_text_template = lambda{|s| ""}
  end

  def convert
    result = ""
    result << convert_element(@document.root, "")
    return result
  end

  def convert_element(element, scope)
    result = nil
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern != nil && element_pattern.any?{|s| s === element.name} && scope_pattern.any?{|s| s === scope}
        result = block.call(element, scope)
        break
      end
    end
    return result || @default_element_template.call(element)
  end

  def pass_element(element, scope, close = true)
    tag = Tag.new(element.name, nil, close)
    element.attributes.each_attribute do |attribute|
      tag[attribute.name] = attribute.to_s
    end
    tag << apply(element, scope)
    return tag
  end

  def convert_text(text, scope)
    result = nil
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern == nil && scope_pattern.any?{|s| s === scope}
        result = block.call(text, scope)
        break
      end
    end
    return result || @default_text_template.call(text)
  end

  def pass_text(text, scope)
    string = text.to_s
    return string
  end

  def apply(element, scope)
    result = ""
    element.children.each do |child|
      case child
      when Element
        tag = convert_element(child, scope)
        if tag
          result << tag
        end
      when Text
        string = convert_text(child, scope)
        if string
          result << string
        end
      end
    end
    return result
  end

  def call(element, name, *args, &arg_block)
    result = []
    @functions.each do |function_name, block|
      if function_name == name
        result = block.call(element, *args, &arg_block)
        break
      end
    end
    return result
  end

  def add(element_pattern, scope_pattern, &block)
    @templates.store([element_pattern, scope_pattern], block)
  end

  def set(name, &block)
    @functions.store(name, block)
  end

  def add_default(element_pattern, &block)
    if element_pattern
      @default_element_template = block
    else
      @default_text_template = block
    end
  end

end


class ZiphilConverter < PageConverter

  attr_reader :path
  attr_reader :language

  def initialize(document, path, language)
    super(document)
    @path = path
    @language = language
  end

  def deepness
    return @path.split("/").size - WholeZiphilConverter::ROOT_PATHS[@language].count("/") - 2
  end
  
  def url_prefix
    return "../" * self.deepness
  end
  
  def main_type
    return (self.deepness.between?(1, 2) && @path =~ /index\.zml/) ? "content-table" : "main"
  end
  
  def online_url
    root_path = WholeZiphilConverter::ROOT_PATHS[@language]
    domain = WholeZiphilConverter::DOMAINS[@language]
    url = path.gsub(root_path + "/", domain).gsub(/\.zml$/, ".html")
    return url
  end

end


class WholeZiphilConverter

  NAMES = {
    :title => {:ja => "人工言語シャレイア語", :en => "Sheleian Constructed Language"},
    :top => {:ja => "トップ", :en => "Top"},
    :conlang => {:ja => "シャレイア語", :en => "Shaleian"},
    :conlang_grammer => {:ja => "文法書", :en => "Grammar"},
    :conlang_course => {:ja => "入門書", :en => "Introduction"},
    :conlang_database => {:ja => "データベース", :en => "Database"},
    :conlang_culture => {:ja => "文化", :en => "Culture"},
    :conlang_translation => {:ja => "翻訳", :en => "Translations"},
    :conlang_theory => {:ja => "シャレイア語論", :en => "Studies"},
    :conlang_document => {:ja => "資料", :en => "Data"},
    :conlang_table => {:ja => "一覧表", :en => "Tables"},
    :application => {:ja => "自作ソフト", :en => "Softwares"},
    :application_download => {:ja => "ダウンロード", :en => "Download"},
    :application_web => {:ja => "Web アプリ", :en => "Web Application"},
    :diary => {:ja => "日記", :en => "Diary"},
    :diary_conlang => {:ja => "シャレイア語", :en => "Shaleian"},
    :diary_mathematics => {:ja => "数学", :en => "Mathematics"},
    :diary_application => {:ja => "プログラミング", :en => "Programming"},
    :diary_game => {:ja => "ゲーム制作", :en => "Game"},
    :other => {:ja => "その他", :en => "Others"},
    :other_mathematics => {:ja => "数学", :en => "Mathematics"},
    :other_language => {:ja => "自然言語", :en => "Languages"},
    :other_tsuro => {:ja => "Tsuro", :en => "Tsuro"},
    :other_other => {:ja => "その他", :en => "Others"},
    :error => {:ja => "エラー", :en => "Error"},
    :error_error => {:ja => "エラー", :en => "Error"}
  }
  ROOT_PATHS = {
    :ja => BASE_PATH + "/document/lbs_source",
    :en => BASE_PATH + "/document/lbs-en_source"
  }
  FOREIGN_LANGUAGES = {:ja => :en, :en => :ja}
  LANGUAGE_NAMES = {:ja => "日本語", :en => "English"}
  DOMAINS = {:ja => "http://ziphil.com/", :en => "http://en.ziphil.com/"}
  TEMPLATE = File.read(BASE_PATH + "/template/template.html")

  def initialize(args)
    @args = args
  end

  def save
    paths = self.paths
    ftp, user = create_ftp
    paths.each_with_index do |(path, language), index|
      document = nil
      parsing_duration = WholeZiphilConverter.measure do
        parser = create_parser(path)
        document = parser.parse
      end
      conversion_duration = WholeZiphilConverter.measure do
        converter, output_path = create_converter(document, path, language)
        result = converter.convert
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, result)
      end
      upload_duration = WholeZiphilConverter.measure do
        local_path, remote_path = create_upload_paths(user, path, language)
        ftp.put(local_path, remote_path) if ftp
      end
      output = " "
      output << "%3d" % (index + 1)
      output << "\e[37m : \e[36m"
      output << "%4d" % parsing_duration
      output << "\e[37m + \e[36m"
      output << "%4d" % conversion_duration
      output << "\e[37m + \e[35m"
      output << "%4d" % upload_duration
      output << "\e[37m  |  \e[33m"
      output << "#{language} "
      path_array = path.gsub(ROOT_PATHS[language] + "/", "").split("/")
      path_array.map!{|s| (s =~ /\d/) ? "%3d" % s.to_i : s.gsub("index.zml", "  *")[0..2]}
      output << path_array.join(" ")
      output << "\e[37m"
      puts(output)
    end
    puts("-" * 45)
    puts(" " * 35 + "#{"%3d" % paths.size} files")
    ftp.close if ftp
  end

  def paths
    paths = []
    if @args.empty?
      ROOT_PATHS.each do |language, default|
        directories = []
        directories << default
        directories.each do |directory|
          Dir.each_child(directory) do |entry|
            if entry =~ /\.zml/
              paths << [directory + "/" + entry, language]
            end
            unless entry =~ /\./
              directories << directory + "/" + entry
            end
          end
        end
      end
    else
      path = @args.map{|s| s.gsub("\\", "/").gsub("c:/", "C:/")}[0].encode("utf-8")
      language = ROOT_PATHS.find{|s, t| path.include?(t)}&.first
      if language
        paths << [path, language]
      end
    end
    paths.sort_by! do |path, language|
      path_array = path.gsub(ROOT_PATHS[language] + "/", "").gsub(".zml", "").split("/")
      path_array.reject!{|s| s.include?("index")}
      path_array.map!{|s| (s.match(/^\d/)) ? s.to_i : s}
      next [path_array, language]
    end
    return paths
  end

  def create_ftp
    ftp, user = nil, nil
    unless @args.empty?
      config_data = File.read(BASE_PATH + "/converter/config.txt")
      host, user, password = config_data.split("\n")
      ftp = Net::FTP.new(host, user, password)
    end
    return ftp, user
  end

  def create_parser(path)
    source = File.read(path)
    parser = ZenithalParser.new(source)
    parser.brace_name = "x"
    parser.bracket_name = "xn"
    parser.slash_name = "i"
    return parser
  end

  def create_converter(document, path, language)
    converter = ZiphilConverter.new(document, path, language) 
    directory = BASE_PATH + "/template"
    Dir.each_child(directory) do |entry|
      if entry =~ /\.rb/
        converter.instance_eval(File.read(directory + "/" + entry), entry)
      end
    end
    output_path = path.gsub("_source", "").gsub(".zml", ".html")
    return converter, output_path
  end

  def create_upload_paths(user, path, language)
    local_path = path.gsub("_source", "").gsub(".zml", ".html")
    remote_path = path.gsub(ROOT_PATHS[language], "").gsub(".zml", ".html")
    unless language == :ja
      remote_path = "/#{language}.#{user}" + remote_path
    end
    return local_path, remote_path
  end

  def self.measure(&block)
    before_time = Time.now
    block.call
    duration = (Time.now - before_time) * 1000
    return duration
  end

end


converter = WholeZiphilConverter.new(ARGV)
converter.save