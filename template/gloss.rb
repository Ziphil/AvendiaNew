# coding: utf-8


converter.add(["gloss"], ["page.xl.li"]) do |element|
  tag = TagBuilder.new("ul")
  item_tag = TagBuilder.new("li", "gloss")
  item_tag << apply(element, "page.gloss")
  tag << item_tag
  next tag
end

converter.add(["gloss"], ["page"]) do |element|
  tag = TagBuilder.new("div", "gloss")
  tag << apply(element, "page.gloss")
  next tag
end

converter.add(["li"], ["page.gloss"]) do |element|
  tag = TagBuilder.new("div", "word")
  tag << apply(element, "page.gloss.li")
  next tag
end

converter.add(nil, ["page.gloss"]) do |text|
  if text.previous_sibling && text.next_sibling
    string = text.to_s
  else
    string = ""
  end
  next string
end

converter.add(["sh", "ex"], ["page.gloss.li"]) do |element|
  case element.name
  when "sh"
    tag = TagBuilder.new("div", "name")
  when "ex"
    tag = TagBuilder.new("div", "explanation")
  end
  tag << apply(element, "page")
  next tag
end

converter.add(["mph"], ["page"]) do |element|
  tag = TagBuilder.new("span", "morpheme")
  tag << apply(element, "page")
  next tag
end