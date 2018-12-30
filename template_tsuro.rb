# coding: utf-8


ROTATION_SYMBOLS = {"T" => 0, "R" => 1, "B" => 2, "L" => 3}
BORDER_SYMBOLS = {"t" => "top", "r" => "right", "b" => "bottom", "l" => "left"}

converter.add(["t"], ["page"]) do |element|
  tag = TagBuilder.new("span", "tile")
  query = element.attribute("q").to_s
  if match = query.match(/^([0-9]+)([A-Z])?$/)
    number = match[1].to_i
    rotation = ROTATION_SYMBOLS[match[2]] || 0
    number_tag = TagBuilder.new("span")
    number_tag << number.to_s
    image_tag = TagBuilder.new("img", nil, false)
    image_tag["src"] = self.url_prefix + "material/tsuro/#{number + 1}.png"
    image_tag["style"] = "transform: rotate(#{rotation * 90}deg)"
    tag << number_tag
    tag << image_tag
  end
  next tag
end

converter.add(["board"], ["page"]) do |element|
  tag = TagBuilder.new("table", "board")
  tag << apply(element, "page.board")
  next tag
end

converter.add(["row"], ["page.board"]) do |element|
  tag = TagBuilder.new("tr")
  tag << apply(element, "page.board.row")
  next tag
end

converter.add(["t"], ["page.board.row"]) do |element|
  tag = TagBuilder.new("td", "tile")
  query = element.attribute("q").to_s
  if match = query.match(/^([0-9]+)([A-Z])$/)
    number = match[1].to_i
    rotation = ROTATION_SYMBOLS[match[2]]
    image_tag = TagBuilder.new("img", nil, false)
    image_tag["src"] = self.url_prefix + "material/tsuro/#{number + 1}.png"
    image_tag["style"] = "transform: rotate(#{rotation * 90}deg)"
    information_tag = TagBuilder.new("div", "information")
    information_tag << number.to_s + match[2].to_s
    tag << image_tag
    tag << information_tag
  end
  explanation_tag = TagBuilder.new("div", "explanation")
  explanation_tag << apply(element, "page")
  if element.attribute("hue")
    hue = element.attribute("hue").to_s
    explanation_tag["style"] = "background-color: hsla(#{hue}, 100%, 50%, 0.2)"
  end
  tag << explanation_tag
  next tag
end

converter.add(["e"], ["page.board.row"]) do |element|
  tag = TagBuilder.new("td", "edge")
  query = element.attribute("q").to_s
  if match = query.match(/^([0-9])$/)
    tag["class"] << " row"
  elsif match = query.match(/^([A-Z])$/)
    tag["class"] << " column"
  end
  if element.attribute("bd")
    tag["class"] << " border-" + BORDER_SYMBOLS[element.attribute("bd").to_s]
  end
  tag << query
  next tag
end