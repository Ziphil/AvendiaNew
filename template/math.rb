# coding: utf-8


converter.add(["use-math"], ["header"]) do |element|
  this = ""
  this << Tag.build("style") do |this|
    font_url = converter.url_prefix + "material/font/math.otf"
    this << ZenmathParserMethod.create_style_string(font_url)
  end
  this << Tag.build("script") do |this|
    this << ZenmathParserMethod.create_script_string
  end
  next this + "\n"
end

converter.add(["math-inline"], ["page"]) do |element|
  this = ""
  this << apply(element, "html")
  next this
end

converter.add(["math-block"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "math-block") do |this|
    this << apply(element, "html")
  end
  next this
end