# coding: utf-8


converter.add(["error"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "error") do |this|
    this << apply(element, "page.error")
  end
  next this
end

converter.add(["code"], ["page.error"]) do |element|
  this = ""
  this << Tag.build("div", "error-code") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["message"], ["page.error"]) do |element|
  this = ""
  this << Tag.build("div", "message") do |this|
    this << apply(element, "page")
  end
  next this
end