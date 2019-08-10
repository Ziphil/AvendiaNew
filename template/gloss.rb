# coding: utf-8


converter.add(["gloss"], ["page.xl.li"]) do |element|
  this = ""
  this << Tag.build("ul") do |this|
    this << Tag.build("li", "gloss") do |this|
      this << apply(element, "page.gloss")
    end
  end
  next this
end

converter.add(["gloss"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "gloss") do |this|
    this << apply(element, "page.gloss")
  end
  next this
end

converter.add(["li"], ["page.gloss"]) do |element|
  this = ""
  this << Tag.build("div", "word") do |this|
    this << apply(element, "page.gloss.li")
  end
  next this
end

converter.add(nil, ["page.gloss"]) do |text|
  if text.previous_sibling && text.next_sibling
    previous_sibling = text.previous_sibling
    next_sibling = text.next_sibling
    if previous_sibling.is_a?(Element) && previous_sibling.attribute("punc")&.value =~ /(\(|\[|«|“)$/
      string = ""
    elsif next_sibling.is_a?(Element) && next_sibling.attribute("punc")&.value =~ /^(\)|\.|,|!|\?)/
      string = ""
    else
      string = text.to_s
    end
  else
    string = ""
  end
  next string
end

converter.add(["sh", "bs", "ex"], ["page.gloss.li"]) do |element|
  this = ""
  this << Tag.build("div") do |this|
    case element.name
    when "sh"
      this.class = "name"
    when "bs"
      this.class = "base"
    when "ex"
      this.class = "explanation"
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["mph"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "morpheme") do |this|
    this << apply(element, "page")
  end
  next this
end