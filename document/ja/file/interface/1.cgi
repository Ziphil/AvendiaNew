#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require 'json'
require 'open-uri'
require_relative '../../file/module/1'
require_relative '../../file/module/2'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class ShaleiaUploader

  PASSWORD = File.read("../../file/dictionary/meta/other/password.txt")
  GOOGLE_URL = "https://script.google.com/macros/s/AKfycbxLhjMTVq4ybjW2waZp5xgbo2emqBMBkOkz-XMx-GzjA2W4K8M/exec"
  GITHUB_URL = "https://raw.githubusercontent.com/"

  def initialize(body, cgi)
    @body = body
    @cgi = cgi
  end

  def run
    fetch_github
  rescue => exception
    error(exception.message + "\n  " + exception.backtrace.join("\n  "))
  end

  def fetch_github
    output = ""
    parsed_body = JSON.parse(@body)
    repository_name = parsed_body["repository"]["full_name"]
    after_hash = parsed_body["after"]
    previous_size = ShaleiaUtilities.names(0).size
    new_size = nil
    Kernel.open(GITHUB_URL + repository_name + "/" + after_hash + "/1.xdc") do |file|
      ShaleiaUtilities.upload(file, 0)
      ShaleiaUtilities.update(0)
      new_size = ShaleiaUtilities.names(0).size
    end
    Kernel.open(GOOGLE_URL + "?mode=update&password=#{PASSWORD}&previous=#{previous_size}&new=#{new_size}") do |file|
      file.each_line do |line| 
        output << line
      end
    end
    @cgi.out("text/plain") do
      next output
    end
  end

  def error(message)
    output = ""
    message.gsub(/^(\s*)(.+)\.(rb|cgi):/){"#{$1}****.#{$3}:"}.each_line do |line|
      output << line.rstrip
      output << "\n"
    end
    @cgi.out("text/plain") do
      next output
    end
  end

end


ShaleiaUploader.new(STDIN.read, CGI.new).run