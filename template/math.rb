# coding: utf-8


THEOREM_TYPE_CLASSES = {"def" => "definition", "thm" => "theorem", "prp" => "proposition", "lem" => "lemma", "cor" => "corollary"}

converter.define_singleton_method(:reset_variables) do
  converter.variables[:number] = Hash.new{|h, s| h[s] = 0}
  converter.variables[:numbers] = Hash.new{|h, s| h[s] = {}}
end

converter.reset_variables

converter.define_singleton_method(:set_number) do |type, id|
  converter.variables[:number][type] += 1
  converter.variables[:numbers][type][id] = converter.variables[:number][type]
end

converter.define_singleton_method(:get_number) do |type, id|
  numbers = converter.variables[:numbers][type]
  if numbers.key?(id)
    next numbers[id]
  else
    element = converter.document.root.each_xpath("//*[@id='#{id}']")
    if element
      case type
      when :equation
        number = element.each_xpath("preceding::math-block[@id]").to_a.size + 1
      when :theorem
        number = element.each_xpath("preceding::thm").to_a.size + 1
      end
      numbers[id] = number
      next number
    else
      next "?"
    end
  end
end

converter.add(["use-math"], ["header"]) do |element|
  this = ""
  converter.reset_variables
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
    set_number(:equation, id)
  end
  this << Tag.build("span", "math-block") do |this|
    this << Tag.build("span", "math-wrapper") do |this|
      this << apply(element, "html")
    end
    if id
      this["id"] = id
      this << Tag.build("span", "number") do |this|
        this << get_number(:equation, id).to_s
      end
    end
  end
  next this
end

converter.add(["em"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "emphasis") do |this|
    this << apply(element, "page")
  end
end

converter.add(["thm"], ["page"]) do |element|
  this = ""
  id = element.attribute("id")&.to_s
  type = element.attribute("type").to_s
  set_number(:theorem, id)
  this << Tag.build("div", "theorem") do |this|
    this["class"] += " " + THEOREM_TYPE_CLASSES[type]
    this << Tag.build("span", "number") do |this|
      this << get_number(:theorem, id).to_s
      label_element = element.elements.to_a("label").first
      if label_element
        this << " ["
        this << apply(label_element, "page")
        this << "]"
      end
    end
    this << apply(element, "page")
    if id
      this["id"] = id
    end
  end
end

converter.add(["prf"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "proof") do |this|
    this << Tag.build("span", "number") do |this|
      this << ""
    end
    this << apply(element, "page")
  end
end

converter.add(["ref"], ["page"]) do |element|
  this = ""
  if element.attribute("eq")
    type = :equation
    id = element.attribute("eq").to_s
  elsif element.attribute("thm")
    type = :theorem
    id = element.attribute("thm").to_s
  elsif element.attribute("bib")
    type = :bibliography
    id = element.attribute("bib").to_s
  end
  this << Tag.build("span") do |this|
    this << get_number(type, id).to_s
  end
end