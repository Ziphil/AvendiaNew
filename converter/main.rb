# coding: utf-8


require 'pp'
require 'fileutils'
require 'listen'
require 'net/ftp'
require 'io/console'
require 'rexml/document'
require 'selenium-webdriver'
require 'zenml'
include REXML
include Zenithal

BASE_PATH = File.expand_path("..", File.dirname($0)).encode("utf-8")

Kernel.load(BASE_PATH + "/converter/utility.rb")
Kernel.load(BASE_PATH + "/converter/word_converter.rb")
Encoding.default_external = "UTF-8"
$stdout.sync = true


class AvendiaParser < ZenithalParser

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


class AvendiaConverter < ZenithalConverter

  attr_reader :path
  attr_reader :language

  def initialize(document, path, language)
    super(document, :text)
    @path = path
    @language = language
  end

  def update(document, path, language)
    @document = document
    @configs = {}
    @path = path
    @language = language
  end

  def pass_element(element, scope, close = true)
    tag = Tag.new(element.name, nil, close)
    element.attributes.each_attribute do |attribute|
      tag[attribute.name] = attribute.to_s
    end
    tag << apply(element, scope)
    return tag
  end

  def pass_text(text, scope)
    string = text.to_s
    return string
  end

  def deepness
    return @path.split("/").size - WholeAvendiaConverter::ROOT_PATHS[@language].count("/") - 2
  end
  
  def url_prefix
    return "../" * self.deepness
  end
  
  def main_type
    return (self.deepness.between?(1, 2) && @path =~ /index\.zml/) ? "content-table" : "main"
  end
  
  def online_url
    root_path = WholeAvendiaConverter::ROOT_PATHS[@language]
    domain = WholeAvendiaConverter::DOMAINS[@language]
    url = path.gsub(root_path, domain).gsub(/\.zml$/, ".html")
    return url
  end

end


class WholeAvendiaConverter

  LOCAL_SERVER_PATH = File.read(BASE_PATH + "/config/local.txt")
  ONLINE_SERVER_CONFIG = File.read(BASE_PATH + "/config/online.txt")
  LOCAL_DOMAINS = {
    :ja => "http://lbs.localhost",
    :en => "http://en.lbs.localhost"
  }
  DOMAINS = {
    :ja => "http://ziphil.com",
    :en => "http://en.ziphil.com"
  }
  ROOT_PATHS = {
    :ja => BASE_PATH + "/document/ja",
    :en => BASE_PATH + "/document/en"
  }
  OUTPUT_PATHS = {
    :ja => LOCAL_SERVER_PATH + "/lbs",
    :en => LOCAL_SERVER_PATH + "/lbs-en"
  }
  LOG_PATHS = {
    :ja => BASE_PATH + "/log/ja.txt",
    :en => BASE_PATH + "/log/en.txt",
    :error => BASE_PATH + "/log/error.txt"
  }
  LOG_SIZE = 1000
  READ_TIMEOUT = 5
  REPETITION_SIZE = 3

  def initialize(args)
    options, rest_args = args.partition{|s| s =~ /^\-\w$/}
    upload = false
    if options.include?("-l")
      @mode = :log
    else
      if options.include?("-u")
        upload = true
      end
      if options.include?("-s")
        @mode = :serve
      else
        @mode = :normal
      end
    end
    @paths = create_paths(rest_args)
    @upload = upload
    @ftp, @user = create_ftp(upload)
    @parser = create_parser
    @converter = create_converter
  end

  def update_ftp
    @ftp&.close
    @ftp, @user = create_ftp(@upload)
  end

  def execute
    case @mode
    when :log
      execute_log
    when :serve
      execute_serve
    when :normal
      execute_normal
    end
    @ftp&.close
  end

  def execute_normal
    size = @paths.size
    failed_paths = []
    @paths.each_with_index do |(path, language), index|
      result = save_normal(path, language, index)
      if result.is_a?(Net::FTPError)
        failed_paths << [path, language, 0]
      end
    end
    unless failed_paths.empty?
      print_whole(size, {:only_line => true})
    end
    failed_paths.each_with_index do |(path, language, count), index|
      result = save_normal(path, language, nil, {:only_upload => true})
      if result.is_a?(Net::FTPError) && count < REPETITION_SIZE
        failed_paths << [path, language, count + 1]
      end
    end
    print_whole(size)
  end

  def execute_serve
    count = 0
    ROOT_PATHS.each do |language, dir|
      listener = Listen.to(dir) do |modified, added, removed|
        update_ftp
        paths = (modified + added).uniq
        paths.each_with_index do |path, index|
          if @paths.any?{|s| s.first == path}
            result = save_normal(path, language, count)
            count += 1
          end
        end
      end
      listener.start
    end
    STDIN.noecho(&:gets)
    print_whole(count)
  end

  def execute_log
    @paths.each_with_index do |(path, language), index|
      result = save_log(path, language, index)
    end
  end

  def save_normal(path, language, index, options = {})
    result, durations = nil, {}
    begin
      unless options[:only_upload]
        durations[:convert] = WholeAvendiaConverter.measure do
          convert_normal(path, language)
        end
      end
      durations[:upload] = WholeAvendiaConverter.measure do
        upload_normal(path, language)
      end
    rescue => error
      print_error(path, language, index, error)
      result = error
    end
    print_normal(path, language, index, durations, result)
    return result
  end

  def save_log(path, language, index)
    result, durations = nil, {}
    begin
      durations[:convert] = WholeAvendiaConverter.measure do
        result = convert_log(path, language)
      end
    rescue => error
      print_error(path, language, index, error)
      result = error
    end
    print_log(path, language, index, durations, result)
    return result
  end

  def convert_normal(path, language)
    extension = File.extname(path).gsub(/^\./, "")
    output_path = path.gsub(ROOT_PATHS[language], OUTPUT_PATHS[language])
    output_path = modify_extension(output_path)
    output_dir = File.dirname(output_path)
    FileUtils.mkdir_p(output_dir)
    case extension
    when "zml"
      @parser.update(File.read(path), path, language)
      document = @parser.parse
      @converter.update(document, path, language)
      output = @converter.convert
      File.write(output_path, output)
    when "scss"
      output = `sass --style=compressed --cache-location='#{OUTPUT_PATHS[language]}/.sass-cache' '#{path}':'#{output_path}'`
    when "ts"
      output = `browserify #{path} -p [tsify -t ES6 --noImplicitAny --strictNullChecks]`
      File.write(output_path, output)
    when "css", "rb", "cgi", "js"
      FileUtils.copy(path, output_path)
    end
  end

  def convert_log(path, language)
    extension = File.extname(path).gsub(/^\./, "")
    case extension
    when "zml"
      @parser.update(File.read(path), path, language)
      document = @parser.parse
      @converter.update(document, path, language)
      output = @converter.convert("change-log")
      time = Time.now - 21600
      log_path = LOG_PATHS[language]
      log_entries = File.read(log_path).lines.map(&:chomp)
      log_entries.unshift(time.strftime("%Y/%m/%d") + "; " + output)
      log_string = log_entries.take(LOG_SIZE).join("\n")
      File.write(log_path, log_string)
    end
  end

  def upload_normal(path, language)
    local_path = path.gsub(ROOT_PATHS[language], OUTPUT_PATHS[language])
    local_path = modify_extension(local_path)
    remote_path = path.gsub(ROOT_PATHS[language], "")
    remote_path = modify_extension(remote_path)
    unless language == :ja
      remote_path = "/#{language}.#{@user}" + remote_path
    end
    @ftp&.put(local_path, remote_path)
  end

  def print_normal(path, language, index, durations, result = nil)
    output = ""
    output << " "
    if index
      output << "%3d" % (index + 1)
    else
      output << "   "
    end
    output << "\e[0m : \e[36m"
    if durations[:convert]
      output << "%4d" % durations[:convert]
    else
      output << "   ?"
    end
    output << "\e[0m + \e[35m"
    if durations[:upload]
      output << "%4d" % durations[:upload]
    else
      output << "   ?"
    end
    output << "\e[0m  |  \e[33m"
    if result
      output << "\e[7m"
    end
    path_array = path.gsub(ROOT_PATHS[language] + "/", "").split("/")
    path_array.map!{|s| (s =~ /\d/) ? "%3d" % s.to_i : s.gsub("index.zml", "  @").slice(0, 3)}
    path_array.unshift(language)
    output << path_array.join(" ")
    output << "\e[0m"
    output << " "
    puts(output)
  end

  def print_log(path, language, index, durations, result = nil)
    output = ""
    print(output)
  end

  def print_whole(size, options = {})
    output = ""
    if size > 0
      output << "-" * 38
      unless options[:only_line]
        output << "\n"
        output << " " * 26 + "#{"%5d" % size} files"
      end
    end
    puts(output)
  end

  def print_error(path, language, index, error)
    output = ""
    output << "[#{language}: #{path}]\n"
    output << error.full_message.gsub(/\e\[.*?[A-Za-z]/, "")
    output << "\n"
    File.open(LOG_PATHS[:error], "a") do |file|
      file.puts(output)
    end
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
    paths.select! do |path, language|
      next File.basename(path, ".*") =~ /^(\d+|index)$/
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
      host, user, password = ONLINE_SERVER_CONFIG.split("\n")
      ftp = Net::FTP.new(host, user, password)
      ftp.read_timeout = READ_TIMEOUT
    end
    return ftp, user
  end

  def create_parser
    parser = AvendiaParser.new("", nil, nil)
    parser.brace_name = "x"
    parser.bracket_name = "xn"
    parser.slash_name = "i"
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
    converter = AvendiaConverter.new(nil, nil, nil)
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
    result.gsub!(/\.ts$/, ".js")
    return result
  end

  def self.measure(&block)
    before_time = Time.now
    block.call
    duration = (Time.now - before_time) * 1000
    return duration
  end

end


whole_converter = WholeAvendiaConverter.new(ARGV)
whole_converter.execute