# coding: utf-8


COLUMN_SYMBOLS = {"A" => 0, "B" => 1, "C" => 2, "D" => 3, "E" => 4, "F" => 5}
ROTATION_SYMBOLS = {"T" => 0, "R" => 1, "B" => 2, "L" => 3}
BORDER_SYMBOLS = {"t" => "top", "r" => "right", "b" => "bottom", "l" => "left"}

converter.add(["t"], ["page"]) do |element|
  this = ""
  query = element.attribute("q").to_s
  this << Tag.build("span", "tile") do |this|
    if match = query.match(/^([0-9]+)([A-Z])?$/)
      number = match[1].to_i
      rotation = ROTATION_SYMBOLS[match[2]] || 0
      this << Tag.build("span") do |this|
        this << query
      end
      this << Tag.build("img", nil, false) do |this|
        this["src"] = converter.url_prefix + "material/tsuro/#{number + 1}.png"
        this["style"] = "transform: rotate(#{rotation * 90}deg)"
      end
    end
  end
  next this
end

converter.add(["board"], ["page"]) do |element|
  this = ""
  corner = element.attribute("c").to_s
  this << Tag.build("table", "board") do |this|
    if match = corner.match(/^([0-9])([A-Z])$/)
      corner_row_number = match[1].to_i - 1
      corner_column_number = COLUMN_SYMBOLS[match[2]].to_i
    end
    row_elements = element.elements.select{|s| s.name == "row"}
    column_size = row_elements.first.elements.size
    this << Tag.build("tr") do |this|
      this << Tag.new("td", "edge")
      column_size.times do |i|
        column_number = corner_column_number + i
        this << Tag.build("td", "edge column") do |this|
          if corner_row_number == 0
            this["class"] << " border-top"
          end
          this << COLUMN_SYMBOLS.invert[column_number]
        end
      end
      this << Tag.new("td", "edge")
    end
    row_elements.each_with_index do |row_element, i|
      row_number = corner_row_number + i
      this << Tag.build("tr") do |this|
        this << Tag.build("td", "edge row") do |this|
          if corner_column_number == 0
            this["class"] << " border-left"
          end
          this << (row_number + 1).to_s
        end
        if row_number % 2 == 0
          this << apply(row_element, "page.board.row")
        else
          this << apply(row_element, "page.board.row-alt")
        end
        this << Tag.build("td", "edge row") do |this|
          if corner_column_number + column_size == 6
            this["class"] << " border-right"
          end
          this << (row_number + 1).to_s
        end
      end
    end
    this << Tag.build("tr") do |this|
      this << Tag.new("td", "edge")
      column_size.times do |i|
        column_number = corner_column_number + i
        this << Tag.build("td", "edge column") do |this|
          if corner_row_number + row_elements.size == 6
            this["class"] << " border-bottom"
          end
          this << COLUMN_SYMBOLS.invert[column_number]
        end
      end
      this << Tag.new("td", "edge")
    end
  end
  next this
end

converter.add(["t"], ["page.board.row", "page.board.row-alt"]) do |element, scope|
  this = ""
  column_number = element.parent.elements.select{|s| s.name == "t"}.index(element)
  query = element.attribute("q").to_s
  this << Tag.build("td", "tile") do |this|
    if scope == "page.board.row"
      if column_number % 2 == 0
        this["class"] << " alternative"
      end
    else
      if column_number % 2 == 1
        this["class"] << " alternative"
      end
    end
    if match = query.match(/^([0-9]+)([A-Z])$/)
      number = match[1].to_i
      rotation = ROTATION_SYMBOLS[match[2]]
      this << Tag.build("img", nil, false) do |this|
        this["src"] = converter.url_prefix + "material/tsuro/#{number + 1}.png"
        this["style"] = "transform: rotate(#{rotation * 90}deg)"
      end
      this << Tag.build("div", "information") do |this|
        this << number.to_s + match[2].to_s
      end
    end
    this << Tag.build("div", "explanation") do |this|
      if element.attribute("hue")
        hue = element.attribute("hue").to_s
        this["style"] = "background-color: hsla(#{hue}, 100%, 50%, 0.2)"
      end
      this << apply(element, "page")
    end
  end
  next this
end