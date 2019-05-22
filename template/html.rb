# coding: utf-8


OPEN_TAG_NAMES = ["br", "img", "hr", "meta", "input", "embed", "area", "base", "link"]

converter.add(["html"], [""]) do |element|
  this = ""
  this << "<!DOCTYPE html>\n\n"
  this << pass_element(element, "html")
  next this
end

converter.add([//], ["html"]) do |element|
  close = !OPEN_TAG_NAMES.include?(element.name)
  this = pass_element(element, "html", close)
  next this
end