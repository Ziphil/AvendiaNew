# coding: utf-8


require 'pp'
require 'fileutils'
require 'delegate'
require 'net/ftp'
require 'rexml/document'
include REXML

BASE_PATH = File.expand_path("..", File.dirname($0)).encode("utf-8")
SERVER_PATH = "C:/Apache24/htdocs"

Kernel.load(BASE_PATH + "/converter/parser.rb")
Kernel.load(BASE_PATH + "/converter/utility.rb")
Kernel.load(BASE_PATH + "/converter/word_converter.rb")
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

  def convert(initial_scope = "")
    result = ""
    result << convert_element(@document.root, initial_scope)
    return result
  end

  def convert_element(element, scope, *args)
    result = nil
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern != nil && element_pattern.any?{|s| s === element.name} && scope_pattern.any?{|s| s === scope}
        result = instance_exec(element, scope, *args, &block)
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

  def convert_text(text, scope, *args)
    result = nil
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern == nil && scope_pattern.any?{|s| s === scope}
        result = instance_exec(text, scope, *args, &block)
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

  def call(element, name, *args)
    result = []
    @functions.each do |function_name, block|
      if function_name == name
        result = instance_exec(element, *args, &block)
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

  def update(document, path, language)
    @document = document
    @configs = {}
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


class ZiphilParser < ZenithalParser

  attr_reader :path
  attr_reader :language

  def initialize(source, path, language)
    super(source)
    @path = path
    @language = language
  end

  def update(source, path, language)
    @source = StringReader.new(source)
    @version = nil
    @path = path
    @language = language
  end

end


class WholeZiphilConverter

  DOMAINS = {
    :ja => "http://ziphil.com/",
    :en => "http://en.ziphil.com/"
  }
  ROOT_PATHS = {
    :ja => BASE_PATH + "/document/ja",
    :en => BASE_PATH + "/document/en"
  }
  OUTPUT_PATHS = {
    :ja => SERVER_PATH + "/lbs",
    :en => SERVER_PATH + "/lbs-en"
  }
  LOG_PATHS = {
    :ja => BASE_PATH + "/log/ja.txt",
    :en => BASE_PATH + "/log/en.txt"
  }
  LOG_SIZE = 1000

  def initialize(args)
    options, rest_args = args.partition{|s| s =~ /^\-\w$/}
    upload = false
    if options.include?("-l")
      @mode = :log
    else
      if options.include?("-u")
        upload = true
      end
      @mode = :normal
    end
    @paths = create_paths(rest_args)
    @ftp, @user = create_ftp(upload)
    @parser = create_parser
    @converter = create_converter
  end

  def save
    case @mode
    when :log
      save_log
    when :normal
      save_normal
    end
    @ftp&.close
  end

  def save_log
    @paths.each_with_index do |(path, language), index|
      document, result = nil, nil
      extension = File.extname(path).gsub(/^\./, "")
      parsing_duration = WholeZiphilConverter.measure do
        document = parse_normal(path, language, extension)
      end
      conversion_duration = WholeZiphilConverter.measure do
        result = convert_log(document, path, language, extension)
      end
    end
  end

  def save_normal
    @paths.each_with_index do |(path, language), index|
      document, result = nil, nil
      extension = File.extname(path).gsub(/^\./, "")
      parsing_duration = WholeZiphilConverter.measure do
        document = parse_normal(path, language, extension)
      end
      conversion_duration = WholeZiphilConverter.measure do
        result = convert_normal(document, path, language, extension)
      end
      upload_duration = WholeZiphilConverter.measure do
        result = upload_normal(path, language)
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
    puts(" " * 35 + "#{"%3d" % @paths.size} files")
  end

  def parse_normal(path, language, extension)
    docment = nil
    case extension
    when "zml"
      @parser.update(File.read(path), path, language)
      document = @parser.parse
    end
    return document
  end

  def convert_normal(document, path, language, extension)
    result = nil
    case extension
    when "zml"
      @converter.update(document, path, language)
      output_path = path.gsub(ROOT_PATHS[language], OUTPUT_PATHS[language])
      output_path = modify_extension(output_path)
      output = @converter.convert
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, output)
    when "scss"
      output_path = path.gsub(ROOT_PATHS[language], OUTPUT_PATHS[language])
      output_path = modify_extension(output_path)
      Kernel.system("sass --style expanded --no-cache #{path}:#{output_path}")
    when "css", "rb", "cgi", "js"
      output_path = path.gsub(ROOT_PATHS[language], OUTPUT_PATHS[language])
      FileUtils.copy(path, output_path)
    end
    return result
  end

  def convert_log(document, path, language, extension)
    result = nil
    case extension
    when "zml"
      @converter.update(document, path, language)
      output = @converter.convert("change-log")
      time = Time.now - 21600
      log_path = LOG_PATHS[language]
      log_entries = File.read(log_path).lines.map(&:chomp)
      log_entries.unshift(time.strftime("%Y/%m/%d") + "; " + output)
      log_string = log_entries.take(LOG_SIZE).join("\n")
      File.write(log_path, log_string)
    end
    return result
  end

  def upload_normal(path, language)
    result = nil
    if @ftp
      local_path = path.gsub(ROOT_PATHS[language], OUTPUT_PATHS[language])
      local_path = modify_extension(local_path)
      remote_path = path.gsub(ROOT_PATHS[language], "")
      remote_path = modify_extension(remote_path)
      unless language == :ja
        remote_path = "/#{language}.#{@user}" + remote_path
      end
      @ftp.put(local_path, remote_path)
    end
    return result
  end

  def create_paths(args)
    paths = []
    if args.empty?
      ROOT_PATHS.each do |language, default|
        directories = []
        directories << default
        directories.each do |directory|
          Dir.each_child(directory) do |entry|
            if entry =~ /\.\w+$/
              paths << [directory + "/" + entry, language]
            end
            unless entry =~ /\./
              directories << directory + "/" + entry
            end
          end
        end
      end
    else
      path = args.map{|s| s.gsub("\\", "/").gsub("c:/", "C:/")}[0].encode("utf-8")
      language = ROOT_PATHS.find{|s, t| path.include?(t)}&.first
      if language
        paths << [path, language]
      end
    end
    paths.map! do |path, language|
      next_path = path.gsub(/v\.scss$/, ".scss")
      next [next_path, language]
    end
    paths.sort_by! do |path, language|
      path_array = path.gsub(ROOT_PATHS[language] + "/", "").gsub(/\.\w+$/, "").split("/")
      path_array.reject!{|s| s.include?("index")}
      path_array.map!{|s| (s.match(/^\d/)) ? s.to_i : s}
      next [path_array, language]
    end
    return paths
  end

  def create_ftp(upload)
    ftp, user = nil, nil
    if upload
      config_data = File.read(BASE_PATH + "/converter/config.txt")
      host, user, password = config_data.split("\n")
      ftp = Net::FTP.new(host, user, password)
    end
    return ftp, user
  end

  def create_parser
    parser = ZiphilParser.new("", nil, nil)
    parser.brace_name = "x"
    parser.bracket_name = "xn"
    parser.slash_name =  "i"
    directory = BASE_PATH + "/macro"
    Dir.each_child(directory) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:parser, parser)
        Kernel.eval(File.read(directory + "/" + entry), binding, entry)
      end
    end
    return parser
  end

  def create_converter
    converter = ZiphilConverter.new(nil, nil, nil)
    directory = BASE_PATH + "/template"
    Dir.each_child(directory) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:converter, converter)
        Kernel.eval(File.read(directory + "/" + entry), binding, entry)
      end
    end
    return converter
  end

  def modify_extension(path)
    result = path.clone
    result.gsub!(/\.zml$/, ".html")
    result.gsub!(/\.scss$/, ".css")
    return result
  end

  def self.measure(&block)
    before_time = Time.now
    block.call
    duration = (Time.now - before_time) * 1000
    return duration
  end

end


whole_converter = WholeZiphilConverter.new(ARGV)
whole_converter.save