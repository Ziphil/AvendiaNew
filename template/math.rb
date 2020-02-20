# coding: utf-8


THEOREM_TYPE_CLASSES = {"def" => "definition", "thm" => "theorem", "prp" => "proposition", "lem" => "lemma", "cor" => "corollary"}
REFERENCE_TYPE_CLASSES = {"eq" => :equation, "thm" => :theorem, "bib" => :bibliography}

converter.define_singleton_method(:reset_variables) do
  converter.variables = {}
  converter.variables[:latest] = false
  converter.variables[:number] = Hash.new{|h, s| h[s] = 0}
  converter.variables[:numbers] = Hash.new{|h, s| h[s] = {}}
end

converter.define_singleton_method(:set_number) do |type, id|
  converter.variables[:number][type] += 1
  converter.variables[:numbers][type][id] = converter.variables[:number][type]
end

converter.define_singleton_method(:get_number) do |type, id|
  numbers = converter.variables[:numbers][type]
  if numbers.key?(id)
    next numbers[id]
  else
    element = converter.document.root.each_xpath("//*[name()!='ref' and @id='#{id}']").to_a.first
    if element
      case type
      when :equation
        number = element.each_xpath("preceding::math-block[@id]").to_a.size + 1
      when :theorem
        number = element.each_xpath("preceding::thm").to_a.size + 1
      when :bibliography
        number = element.each_xpath("preceding-sibling::li").to_a.size + 1
      end
      numbers[id] = number
      next number
    else
      next "?"
    end
  end
end

converter.define_singleton_method(:create_script_string) do
  unless converter.configs[:script_created]
    command = "npm run -s uglifyjs"
    Open3.popen3(command) do |stdin, stdout, stderr, thread|
      stdin.puts(ZoticaBuilder.create_script_string)
      stdin.close
      converter.configs[:script_string] = stdout.read
      converter.configs[:script_created] = true
    end
  end
end

converter.add(["use-math"], ["header"]) do |element|
  this = ""
  converter.create_script_string
  converter.reset_variables
  this << Tag.build("style") do |this|
    font_url = converter.url_prefix + "material/font/math.otf"
    this << ZoticaBuilder.create_style_string(font_url)
  end
  this << Tag.build("script") do |this|
    this << converter.configs[:script_string]
  end
  next this + "\n"
end

converter.add(["math-inline"], ["page"]) do |element|
  this = ""
  this << apply(element, "math-html")
  next this
end

converter.add(["math-block"], ["page"]) do |element|
  this = ""
  id = element.attribute("id")&.to_s
  mark_element = element.elements.to_a("math-root/math-mark").first
  if id
    set_number(:equation, id)
  end
  this << Tag.build("span", "math-block") do |this|
    this << Tag.build("span", "math-wrapper") do |this|
      this << apply(element, "math-html")
    end
    if id
      this["id"] = id
      this << Tag.build("span", "number") do |this|
        this << get_number(:equation, id).to_s
      end
    end
    if mark_element
      this << Tag.build("span", "mark") do |this|
        this << apply(mark_element, "math-html")
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
  id = element.attribute("id")&.to_s
  type = element.attribute("type")&.to_s
  type_class = REFERENCE_TYPE_CLASSES[type]
  this << Tag.build("span") do |this|
    this["class"] = type_class.to_s
    this << get_number(type_class, id).to_s
  end
end

converter.add(["math-mark"], ["math-html"]) do |element|
  next ""
end

converter.add([//], ["math-html"]) do |element|
  this = pass_element(element, "math-html")
  next this
end