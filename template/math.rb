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
  id = element.attribute("id")&.to_s
  if id
    number = element.each_xpath("preceding::math-block[@id]").to_a.size + 1
  end
  this << Tag.build("span", "math-block") do |this|
    this["id"] = id
    this << Tag.build("span", "math-wrapper") do |this|
      this << apply(element, "html")
    end
    if id
      this << Tag.build("span", "number") do |this|
        this << number.to_s
      end
    end
  end
  next this
end

converter.add(["em"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "em") do |this|
    this << apply(element, "page")
  end
end

converter.add(["ref"], ["page"]) do |element|
  this = ""
  id = element.attribute("eq").to_s
  number = element.each_xpath("//math-block[@id='#{id}']/preceding::math-block[@id]").to_a.size + 1
  this << Tag.build("span") do |this|
    this << number.to_s
  end
end