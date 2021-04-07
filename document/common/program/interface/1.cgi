#! ruby
# coding: utf-8


require 'json'
require 'open-uri'
require_relative 'module/backend'
require_relative 'module/shaleia'


class ShaleiaUploader < BackendBase

  PASSWORD = File.read("../../file/dictionary/meta/other/password.txt")
  GOOGLE_URL = "https://script.google.com/macros/s/AKfycbxLhjMTVq4ybjW2waZp5xgbo2emqBMBkOkz-XMx-GzjA2W4K8M/exec"
  GITHUB_URL = "https://raw.githubusercontent.com/"
  DEFAULT_FILE_NAME = "5.5.xdc"
  VERSIONS = {"5.5" => 0, "1.2" => 1, "3.6" => 2, "2.7" => 3, "3.4" => 4}

  def switch
    fetch_zpdic
  end

  def fetch_github
    output = ""
    parsed_body = JSON.parse(self.body)
    repository_name = parsed_body["repository"]["full_name"]
    after_hash = parsed_body["after"]
    file_name = parsed_body["head_commit"]["modified"][0] || DEFAULT_FILE_NAME
    version = VERSIONS[File.basename(file_name, ".*")]
    previous_size = ShaleiaUtilities.fetch_names(version).size
    new_size = nil
    Kernel.open(GITHUB_URL + repository_name + "/" + after_hash + "/" + file_name) do |file|
      ShaleiaUtilities.upload(file, version)
      ShaleiaUtilities.update(version)
      new_size = ShaleiaUtilities.fetch_names(version).size
    end
    Kernel.open(GOOGLE_URL + "?mode=update&password=#{PASSWORD}&previous=#{previous_size}&new=#{new_size}") do |file|
      file.each_line do |line| 
        output << line
      end
    end
    respond(output, :text)
  end

  def fetch_zpdic
    if self["password"] == PASSWORD
      output = {}
      previous_size = ShaleiaUtilities.fetch_names.size
      ShaleiaUtilities.upload(self["content"])
      ShaleiaUtilities.update
      new_size = ShaleiaUtilities.fetch_names.size
      output["previous_size"] = previous_size
      output["new_size"] = new_size
      output["status"] = "done"
      output["gas_output"] = ""
      Kernel.open(GOOGLE_URL + "?mode=update&password=#{PASSWORD}&previous=#{previous_size}&new=#{new_size}") do |file|
        file.each_line do |line| 
          output["gas_output"] << line
        end
      end
      respond(output)
    else
      respond_errpr("password incorrect")
    end
  end

end


ShaleiaUploader.new(nil, CGI.new).run