# coding: utf-8


require 'bundler/setup'
Bundler.require

include REXML
include Zenithal

BASE_PATH = File.expand_path("..", File.dirname($0)).encode("utf-8")

Kernel.load(File.join(BASE_PATH, "converter/utility.rb"))
Kernel.load(File.join(BASE_PATH, "converter/transformer.rb"))
Kernel.load(File.join(BASE_PATH, "converter/word_converter.rb"))
Kernel.load(File.join(BASE_PATH, "converter/config.rb"))
Encoding.default_external = "UTF-8"
$stdout.sync = true

CONFIG = AvendiaConfig.new(File.join(BASE_PATH, "config/config.json"))


class AvendiaParser < ZoticaParser

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

  attr_reader :document
  attr_reader :path
  attr_reader :language
  attr_reader :variables

  def initialize(document, path, language)
    super(document, :text)
    @path = path
    @language = language
    @variables = {}
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
    return @path.split("/").size - CONFIG.document_dir(@language).count("/") - 1
  end
  
  def url_prefix
    return "../" * self.deepness
  end
  
  def main_type
    return (self.deepness.between?(1, 2) && @path =~ /index\.zml/) ? "content-table" : "main"
  end
  
  def remote_url
    document_path = CONFIG.document_dir(@language)
    domain = CONFIG.remote_domain(@language)
    url = @path.gsub(document_path, domain).gsub(/\.zml$/, ".html")
    return url
  end

  def remote_domain
    domain = CONFIG.remote_domain(@language)
    return domain
  end

end


class WholeAvendiaConverter

  LOG_SIZE = 1000
  READ_TIMEOUT = 5
  REPETITION_SIZE = 3

  def initialize(args)
    options, rest_args = args.partition{|s| s =~ /^\-\w$/}
    upload = false
    if options.include?("-l")
      @mode = :log
    elsif options.include?("-t")
      @mode = :transform
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
    @rest_args = rest_args
    @upload = upload
    @paths = create_paths
    @ftp, @user = create_ftp
    @parser = create_parser
    @converter = create_converter
  end

  def update_ftp
    @ftp&.close
    @ftp, @user = create_ftp
  end

  def execute
    case @mode
    when :log
      execute_log
    when :transform
      execute_transform
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
    CONFIG.document_dirs.each do |language, dir|
      listener = Listen.to(dir) do |modified, added, removed|
        update_ftp
        unless added.empty?
          @paths = create_paths
        end
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

  def execute_transform
    @paths.each_with_index do |(path, language), index|
      input = File.read(path)
      transformer = GreekTransformer.new(input, path, language)
      output = transformer.transform
      File.write(path, output)
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
    output_path = path.gsub(CONFIG.document_dir(language), CONFIG.output_dir(language))
    output_path = modify_extension(output_path)
    output_dir = File.dirname(output_path)
    FileUtils.mkdir_p(output_dir)
    case extension
    when "zml"
      @parser.update(File.read(path), path, language)
      document = @parser.run
      @converter.update(document, path, language)
      output = @converter.convert
      File.write(output_path, output)
    when "scss"
      option = {}
      option[:style] = :compressed
      option[:filename] = path
      option[:cache_location] = File.join(CONFIG.output_dir(language), ".sass-cache")
      output = SassC::Engine.new(File.read(path), option).render
      File.write(output_path, output)
    when "ts"
      command = "npm run -s browserify -- #{path}"
      output = Command.exec(command)
      File.write(output_path, output)
    when "css", "rb", "cgi", "js"
      output = File.read(path)
      File.write(output_path, output)
    else
      raise StandardError.new("unknown file type")
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
      log_path = CONFIG.log_path(language)
      log_entries = File.read(log_path).lines.map(&:chomp)
      log_entries.unshift(time.strftime("%Y/%m/%d") + "; " + output)
      log_string = log_entries.take(LOG_SIZE).join("\n")
      File.write(log_path, log_string)
    end
  end

  def upload_normal(path, language)
    local_path = path.gsub(CONFIG.document_dir(language), CONFIG.output_dir(language))
    local_path = modify_extension(local_path)
    remote_path = path.gsub(CONFIG.document_dir(language), CONFIG.remote_dir(language))
    remote_path = modify_extension(remote_path)
    @ftp&.puttextfile(local_path, remote_path)
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
    path_array = path.gsub(CONFIG.document_dir(language), "").split("/")
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
    File.open(CONFIG.error_log_path, "a") do |file|
      file.puts(output)
    end
  end

  def create_paths
    paths = []
    if @rest_args.empty?
      CONFIG.document_dirs.each do |language, default|
        dirs = []
        dirs << default
        dirs.each do |dir|
          Dir.each_child(dir) do |entry|
            if entry =~ /\.\w+$/
              paths << [File.join(dir, entry), language]
            end
            unless entry =~ /\./
              dirs << File.join(dir, entry)
            end
          end
        end
      end
    else
      path = @rest_args.map{|s| s.gsub("\\", "/").gsub("c:/", "C:/")}[0].encode("utf-8")
      language = CONFIG.document_dirs.find{|s, t| path.include?(t)}&.first
      if language
        paths << [path, language]
      end
    end
    paths.select! do |path, language|
      next File.basename(path, ".*") =~ /^(\d+|index)$/
    end
    paths.sort_by! do |path, language|
      path_array = path.gsub(CONFIG.document_dir(language), "").gsub(/\.\w+$/, "").split("/")
      path_array.reject!{|s| s.include?("index")}
      path_array.map!{|s| (s.match(/^\d/)) ? s.to_i : s}
      next [path_array, language]
    end
    return paths
  end

  def create_ftp
    ftp, user = nil, nil
    if @upload
      ftp = Net::FTP.new(CONFIG.server_host, CONFIG.server_user, CONFIG.server_password)
      ftp.read_timeout = READ_TIMEOUT
    end
    return ftp, user
  end

  def create_parser
    parser = AvendiaParser.new("", nil, nil)
    parser.brace_name = "x"
    parser.bracket_name = "xn"
    parser.slash_name = "i"
    dir = CONFIG.macro_dir
    Dir.each_child(dir) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:parser, parser)
        Kernel.eval(File.read(File.join(dir, entry)), binding, entry)
      end
    end
    return parser
  end

  def create_converter
    converter = AvendiaConverter.new(nil, nil, nil)
    dir = CONFIG.template_dir
    Dir.each_child(dir) do |entry|
      if entry.end_with?(".rb")
        binding = TOPLEVEL_BINDING
        binding.local_variable_set(:converter, converter)
        Kernel.eval(File.read(File.join(dir, entry)), binding, entry)
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