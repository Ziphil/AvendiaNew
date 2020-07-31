# coding: utf-8


THEOREM_TYPE_CLASSES = {"def" => "definition", "thm" => "theorem", "prp" => "proposition", "lem" => "lemma", "cor" => "corollary", "axm" => "axiom"}
THEOREM_TYPE_NAMES = {"def" => "定義", "thm" => "定理", "prp" => "命題", "lem" => "補題", "cor" => "系", "axm" => "公理"}
REFERENCE_TYPE_CLASSES = {"eq" => :equation, "thm" => :theorem, "cthm" => :clever_theorem, "bib" => :bibliography}

converter.define_singleton_method(:reset_variables) do
  variables[:latest] = false
  variables[:number] = Hash.new{|h, s| h[s] = 0}
  variables[:numbers] = Hash.new{|h, s| h[s] = {}}
  variables[:prefixes] = Hash.new{|h, s| h[s] = {}}
end

converter.define_singleton_method(:create_prefix) do |type, element = nil|
  prefix = nil
  if element
    case type
    when :theorem
      prefix = THEOREM_TYPE_NAMES[element.attribute("type")&.to_s]
    end
  end
  next prefix
end

converter.define_singleton_method(:set_number) do |type, id, element = nil|
  variables[:number][type] += 1
  variables[:numbers][type][id] = variables[:number][type]
  variables[:prefixes][type][id] = create_prefix(type, element)
end

converter.define_singleton_method(:get_number) do |type, id|
  number, prefix = "?", nil
  if variables[:numbers][type].key?(id)
    number = variables[:numbers][type][id]
    prefix = variables[:prefixes][type][id]
  else
    element = converter.document.root.each_xpath("//*[name()!='ref' and @id='#{id}']").to_a.first
    if element
      case type
      when :equation
        number = element.each_xpath("preceding::math-block[@id]").to_a.size + 1
      when :theorem, :clever_theorem
        number = element.each_xpath("preceding::thm").to_a.size + 1
        if type == :clever_theorem
          type = :theorem
          prefix = create_prefix(type, element)
        end
      when :bibliography
        number = element.each_xpath("preceding-sibling::li").to_a.size + 1
      end
      variables[:numbers][type][id] = number
      variables[:prefixes][type][id] = prefix
    end
  end
  string = (prefix) ? prefix.to_s + " " + number.to_s : number.to_s
  next string
end

converter.define_singleton_method(:create_script_string) do
  unless configs[:script_created]
    command = "npm run -s uglifyjs"
    Open3.popen3(command) do |stdin, stdout, stderr, thread|
      stdin.puts(ZoticaBuilder.create_script_string)
      stdin.close
      configs[:script_string] = stdout.read
      configs[:script_created] = true
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
    this << configs[:script_string]
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
  this << Tag.build("span", "math-block-wrapper") do |this|
    this << Tag.build("span", "math-block") do |this|
      this << Tag.build("span", "math-wrapper") do |this|
        this << apply(element, "math-html")
      end
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
      name_element = element.elements.to_a("name").first
      if name_element
        this << " ["
        this << apply(name_element, "page")
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