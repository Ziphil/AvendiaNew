# coding: utf-8


class AvendiaConfig

  def initialize(path)
    @path = path
    @json = JSON.parse(File.read(path))
  end

  def server_host
    return @json["server"]["host"]
  end

  def server_user
    return @json["server"]["user"]
  end

  def server_password
    return @json["server"]["password"]
  end

  def local_domain(language)
    return @json["local_domain"][language.to_s]
  end

  def online_domain(language)
    return @json["online_domain"][language.to_s]
  end

  def document_dir(language)
    return BASE_PATH + @json["document_dir"][language.to_s]
  end

  def document_dirs
    result = @json["document_dir"].map do |language, dir|
      next [language.intern, BASE_PATH + dir]
    end
    return result
  end

  def output_dir(language)
    return @json["output_dir"][language.to_s]
  end

  def log_path(language)
    return BASE_PATH + @json["log_path"][language.to_s]
  end

  def error_log_path
    return BASE_PATH + @json["log_path"]["error"]
  end

end