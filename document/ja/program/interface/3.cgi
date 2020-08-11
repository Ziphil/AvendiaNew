#!/usr/bin/ruby
# coding: utf-8


require 'date'
require_relative '../../program/module/1'
require_relative '../../program/module/4'


class ShaleiaInterface < BackendBase

  def switch
    case @command
    when "fetch_word_size"
      fetch_word_size
    when "fetch_progress"
      fetch_progress
    end
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

end


ShaleiaInterface.new(nil, CGI.new).run