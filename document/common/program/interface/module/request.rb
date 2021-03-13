# coding: utf-8


module RequestUtilities

  module_function

  def fetch
    requests = Array.new
    if File.exist?("../../file/dictionary/meta/request/1.txt")
      File.open("../../file/dictionary/meta/request/1.txt") do |file|
        file.each_line do |line|
          requests << line.chomp
        end
      end
    end
    return requests
  end

  def add(requests)
    File.open("../../file/dictionary/meta/request/1.txt", "a") do |file|
      requests.each do |request|
        file.puts(request)
      end
    end
  end

  def delete_at(index)
    requests = RequestUtilities.fetch
    requests.delete_at(index)
    File.open("../../file/dictionary/meta/request/1.txt", "w") do |file|
      requests.each do |request|
        file.puts(request)
      end
    end
  end

end