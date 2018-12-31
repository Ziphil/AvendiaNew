# coding: utf-8


COLUMN_SYMBOLS = {"A" => 0, "B" => 1, "C" => 2, "D" => 3, "E" => 4, "F" => 5}
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
  corner = element.attribute("c").to_s
  if match = corner.match(/^([0-9])([A-Z])$/)
    corner_row_number = match[1].to_i - 1
    corner_column_number = COLUMN_SYMBOLS[match[2]].to_i
  end
  row_elements = element.elements.select{|s| s.name == "row"}
  column_size = row_elements.first.elements.size
  first_row_tag = TagBuilder.new("tr")
  first_row_tag << TagBuilder.new("td", "edge")
  column_size.times do |i|
    column_number = corner_column_number + i
    column_tag = TagBuilder.new("td", "edge column")
    if corner_row_number == 0
      column_tag["class"] << " border-top"
    end
    column_tag << COLUMN_SYMBOLS.invert[column_number]
    first_row_tag << column_tag
  end
  first_row_tag << TagBuilder.new("td", "edge")
  tag << first_row_tag
  row_elements.each_with_index do |row_element, i|
    row_tag = TagBuilder.new("tr")
    row_number = corner_row_number + i
    first_column_tag = TagBuilder.new("td", "edge row")
    if corner_column_number == 0
      first_column_tag["class"] << " border-left"
    end
    first_column_tag << (row_number + 1).to_s
    row_tag << first_column_tag
    if row_number % 2 == 0
      row_tag << apply(row_element, "page.board.row")
    else
      row_tag << apply(row_element, "page.board.row-alt")
    end
    last_column_tag = TagBuilder.new("td", "edge row")
    if corner_column_number + column_size == 6
      last_column_tag["class"] << " border-right"
    end
    last_column_tag << (row_number + 1).to_s
    row_tag << last_column_tag
    tag << row_tag
  end
  last_row_tag = TagBuilder.new("tr")
  last_row_tag << TagBuilder.new("td", "edge")
  column_size.times do |i|
    column_number = corner_column_number + i
    column_tag = TagBuilder.new("td", "edge column")
    if corner_row_number + row_elements.size == 6
      column_tag["class"] << " border-bottom"
    end
    column_tag << COLUMN_SYMBOLS.invert[column_number]
    last_row_tag << column_tag
  end
  last_row_tag << TagBuilder.new("td", "edge")
  tag << last_row_tag
  next tag
end

converter.add(["t"], ["page.board.row", "page.board.row-alt"]) do |element, scope|
  tag = TagBuilder.new("td", "tile")
  column_number = element.parent.elements.select{|s| s.name == "t"}.index(element)
  if scope == "page.board.row"
    if column_number % 2 == 0
      tag["class"] << " alternative"
    end
  else
    if column_number % 2 == 1
      tag["class"] << " alternative"
    end
  end
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