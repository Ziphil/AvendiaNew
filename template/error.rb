﻿# coding: utf-8


converter.add(["error"], ["page"]) do |element|
  tag = TagBuilder.new("div", "error")
  tag << apply(element, "page.error")
  next tag
end

converter.add(["code"], ["page.error"]) do |element|
  tag = TagBuilder.new("div", "error-code")
  tag << apply(element, "page")
  next tag
end

converter.add(["message"], ["page.error"]) do |element|
  tag = TagBuilder.new("div", "message")
  tag << apply(element, "page")
  next tag
end