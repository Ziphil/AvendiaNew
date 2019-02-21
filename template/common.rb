# coding: utf-8


LATEST_VERSION_REGEX = /(5\s*代\s*5\s*期|Version\s*5\.5)/
DICTIONARY_URL = "conlang/database/1.cgi"

converter.add(["page"], [""]) do |element|
  path, language = converter.path, converter.language
  deepness = converter.deepness
  virtual_deepness = (path =~ /index\.zml$/) ? deepness - 1 : deepness
  name_tag = TagBuilder.new("div", "name")
  title = ""
  if virtual_deepness >= -1
    first_category = path.split("/")[-deepness - 1]
    first_link_tag = TagBuilder.new("a", "name")
    first_link_tag["href"] = "../../" + first_category
    if virtual_deepness == -1
      first_link_tag << NAMES[:top][language]
    else
      first_link_tag << NAMES[first_category.intern][language]
    end
    name_tag << first_link_tag
  end
  if virtual_deepness >= 1
    second_category = path.split("/")[-deepness]
    united_category = first_category + "_" + second_category
    second_link_tag = TagBuilder.new("a", "name")
    second_link_tag["href"] = "../" + second_category
    second_link_tag << NAMES[united_category.intern][language]
    name_tag << second_link_tag
  end
  if virtual_deepness >= 2
    if element.attribute("link")
      converted_path = path.match(/([0-9a-z\-]+)\.zml/).to_a[1].to_s
      converted_path += (element.attribute("link").value == "c") ? ".cgi" : ".html"
      third_link_tag = TagBuilder.new("a", "name")
      third_link_tag["href"] = converted_path
    else
      third_link_tag = TagBuilder.new("span")
    end
    name_element = element.elements.to_a("name").first
    title = name_element.inner_text(true).gsub("\"", "&quot;")
    third_link_tag << apply(name_element, "page")
    name_tag << third_link_tag
  end
  navigation_string, header_string, main_string = "", "", ""
  navigation_string << name_tag
  navigation_string << apply(element, "navigation")
  header_string << apply(element, "header")
  main_string << apply(element, "page")
  result = TEMPLATE.gsub(/#\{(.*?)\}/){self.instance_eval($1)}.gsub(/\r/, "")
  next result
end

converter.add(["ver"], ["navigation"]) do |element|
  if element.text == "*" || element.text =~ LATEST_VERSION_REGEX
    tag = TagBuilder.new("div", "version")
    converter.configs[:latest] = true
  else
    tag = TagBuilder.new("div", "version-caution")
  end
  tag << apply(element, "page")
  next tag
end

converter.add(nil, ["navigation"]) do |text|
  next ""
end

converter.add(["import-script"], ["header"]) do |element|
  tag = TagBuilder.new("script")
  tag["src"] = converter.url_prefix + "file/script/" + element.attribute("src").to_s
  next tag.to_s + "\n"
end

converter.add(["base"], ["header"]) do |element|
  tag = TagBuilder.new("base")
  tag["href"] = element.attribute("href").to_s
  next tag.to_s + "\n"
end

converter.add(nil, ["header"]) do |text|
  next ""
end

converter.add(["pb"], ["page"]) do |element|
  tag = TagBuilder.new("div", "index-container")
  tag << apply(element, "page")
  next tag
end

converter.add(["hb"], ["page"]) do |element|
  tag = TagBuilder.new("div", "index-header")
  tag << apply(element, "page")
  next tag
end

converter.add(["ab", "abo", "aba", "abd"], ["page"]) do |element|
  case element.name
  when "ab"
    tag = TagBuilder.new("a", "index")
  when "abo"
    tag = TagBuilder.new("a", "old-index")
  when "aba"
    tag = TagBuilder.new("a", "ancient-index")
  when "abd"
    tag = TagBuilder.new("div", "disabled-index")
  end
  element.attributes.each_attribute do |attribute|
    if attribute.name == "date"
      date_tag = TagBuilder.new("span", "date")
      if element.attribute("date").value =~ /^\d+$/
        hairia_tag = TagBuilder.new("span", "hairia")
        hairia_tag << element.attribute("date").to_s
        date_tag << hairia_tag
      else
        date_tag << element.attribute("date").to_s
      end
      tag << date_tag
    else
      tag[attribute.name] = attribute.to_s
    end
  end
  content_tag = TagBuilder.new("span", "content")
  content_tag << apply(element, "page")
  tag << content_tag
  next tag
end

converter.add(["h1", "h2"], ["page"]) do |element|
  tag = TagBuilder.new(element.name)
  element.attributes.each_attribute do |attribute|
    if attribute.name == "number"
      number_tag = TagBuilder.new("span", "number")
      number_tag << element.attribute("number").to_s
      tag["id"] = element.attribute("number").to_s
      tag << number_tag
    else
      tag[attribute.name] = attribute.to_s
    end
  end
  tag << apply(element, "page")
  next tag
end

converter.add(["p"], ["page"]) do |element|
  tag = TagBuilder.new("p")
  tag << apply(element, "page")
  if element.attribute("par")
    additional_tag = TagBuilder.new("span", "paragraph")
    additional_tag << element.attribute("par").to_s
    tag.insert_first(additional_tag)
  end
  if element.attribute("name")
    additional_tag = TagBuilder.new("span", "name")
    additional_tag << element.attribute("name").to_s
    tag.insert_first(additional_tag)
  end
  next tag
end

converter.add(["img"], ["page"]) do |element|
  tag = TagBuilder.new("img", nil, false)
  tag["alt"] = ""
  element.attributes.each_attribute do |attribute|
    tag[attribute.name] = attribute.to_s
  end
  tag << apply(element, "page")
  next tag
end

converter.add(["a"], ["page"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["an"], ["page"]) do |element|
  tag = TagBuilder.new("a", "normal")
  element.attributes.each_attribute do |attribute|
    tag[attribute.name] = attribute.to_s
  end
  tag << apply(element, "page")
  next tag
end

converter.add(["xl"], ["page"]) do |element|
  tag = TagBuilder.new("ul", "conlang")
  tag << apply(element, "page.xl")
  next tag
end

converter.add(["li"], ["page.xl"]) do |element|
  tag = TagBuilder.new("li")
  tag << apply(element, "page.xl.li")
  next tag
end

converter.add(["sh"], ["page.xl.li"]) do |element|
  tag = TagBuilder.new
  tag << apply(element, "page")
  next tag
end

converter.add(["ja"], ["page.xl.li"]) do |element|
  tag = TagBuilder.new("ul")
  item_tag = TagBuilder.new("li")
  item_tag << apply(element, "page")
  tag << item_tag
  next tag
end

converter.add(nil, ["page.xl.li"]) do |text|
  if text.previous_sibling && text.next_sibling
    string = nil
  else
    string = ""
  end
  next string
end

converter.add(["el"], ["page"]) do |element|
  tag = TagBuilder.new("table", "list")
  tag << apply(element, "page.el")
  next tag
end

converter.add(["li"], ["page.el"]) do |element|
  tag = TagBuilder.new("tr")
  tag << apply(element, "page.el.li")
  next tag
end

converter.add(["et", "ed"], ["page.el.li"]) do |element|
  tag = TagBuilder.new("td")
  tag << apply(element, "page")
  next tag
end

converter.add(["trans"], ["page"]) do |element|
  tag = TagBuilder.new("table", "translation")
  tag << apply(element, "page.trans")
  next tag
end

converter.add(["li"], ["page.trans"]) do |element|
  tag = TagBuilder.new("tr")
  tag << apply(element, "page.trans.li")
  next tag
end

converter.add(["ja", "sh"], ["page.trans.li"]) do |element|
  tag = TagBuilder.new("td")
  tag << apply(element, "page")
  next tag
end

converter.add(["section-table"], ["page"]) do |element|
  tag = TagBuilder.new("ul", "section-table")
  section_item_tag = TagBuilder.new("li")
  subsection_tag = TagBuilder.new("ul")
  element.each_xpath("/page/*[name() = 'h1' or name() = 'h2']") do |inner_element|
    case inner_element.name
    when "h1"
      unless section_item_tag.content.empty?
        section_item_tag << subsection_tag unless subsection_tag.content.empty?
        tag << section_item_tag
      end
      section_item_tag = TagBuilder.new("li")
      subsection_tag = TagBuilder.new("ul")
      section_item_tag << apply(inner_element, "page.section-table")
    when "h2"
      subsection_item_tag = TagBuilder.new("li")
      if inner_element.attribute("number")
        number_tag = TagBuilder.new("span", "number")
        link_tag = TagBuilder.new("a")
        number_tag << inner_element.attribute("number").to_s
        link_tag["href"] = "#" + inner_element.attribute("number").to_s
        link_tag << apply(inner_element, "page.section-table")
        subsection_item_tag << number_tag
        subsection_item_tag << link_tag
      elsif inner_element.attribute("id")
        link_tag = TagBuilder.new("a")
        link_tag["href"] = "#" + inner_element.attribute("id").to_s
        link_tag << apply(inner_element, "page.section-table")
        subsection_item_tag << link_tag
      else
        subsection_item_tag << apply(inner_element, "page.section-table")
      end
      subsection_tag << subsection_item_tag
    end
  end
  section_item_tag << subsection_tag unless subsection_tag.content.empty?
  tag << section_item_tag
  next tag
end

converter.add(["ul", "ol"], ["page"]) do |element|
  tag = pass_element(element, "page.ul")
  next tag
end

converter.add(["li"], ["page.ul"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["table"], ["page"]) do |element|
  tag = pass_element(element, "page.table")
  next tag
end

converter.add(["tr"], ["page.table"]) do |element|
  tag = pass_element(element, "page.table.tr")
  next tag
end

converter.add(["th", "td"], ["page.table.tr"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["thl"], ["page.table.tr"]) do |element|
  tag = TagBuilder.new("th", "left")
  tag << apply(element, "page")
  next tag
end

converter.add(["form"], ["page"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["input"], ["page"]) do |element|
  tag = pass_element(element, "page", false)
  next tag
end

converter.add(["textarea"], ["page"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["pdf"], ["page"]) do |element|
  tag = TagBuilder.new("object", "pdf")
  tag["data"] = element.attribute("src").to_s + "#view=FitH&amp;statusbar=0&amp;toolbar=0&amp;navpanes=0&amp;messages=0"
  tag["type"] = "application/pdf"
  next tag
end

converter.add(["slide"], ["page"]) do |element|
  tag = TagBuilder.new("div", "slide")
  script_tag = TagBuilder.new("script", "speakerdeck-embed")
  script_tag["async"] = "async"
  script_tag["data-id"] = element.attribute("id").to_s
  script_tag["data-ratio"] = "1.33333333333333"
  script_tag["src"] = "http://speakerdeck.com/assets/embed.js"
  tag << script_tag
  next tag
end

converter.add(["pre", "samp"], ["page"]) do |element|
  case element.name
  when "pre"
    tag = TagBuilder.new("table", "code")
  when "samp"
    tag = TagBuilder.new("table", "sample")
  end
  string = element.texts.map{|s| s.to_s}.join.gsub(/\A\s*?\n/, "")
  indent_size = string.match(/\A(\s*?)\S/)[1].length
  string = string.rstrip.deindent
  tag << "\n"
  string.each_line do |line|
    row_tag = TagBuilder.new("tr")
    code_tag = TagBuilder.new("td")
    if line =~ /^\s*$/
      code_tag << " "
    else
      code_tag << line.chomp
    end
    row_tag << code_tag
    tag << " " * indent_size
    tag << row_tag
    tag << "\n"
  end
  tag << " " * (indent_size - 2)
  next tag
end

converter.add(["c", "m"], ["page", "page.section-table"]) do |element|
  case element.name
  when "c"
    tag = TagBuilder.new("span", "code")
  when "m"
    tag = TagBuilder.new("span", "monospace")
  end
  element.children.each do |inner_element|
    case inner_element
    when Element
      tag << convert_element(inner_element, "page")
    when Text
      tag << inner_element.to_s
    end
  end
  next tag
end

converter.add(["special"], ["page"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["x"], ["page"]) do |element|
  content = apply(element, "page").to_s
  url = converter.url_prefix + DICTIONARY_URL
  link = !!converter.configs[:latest] && converter.path =~ /conlang\/.+\/\d+(\-\w{2})?\.zml/
  tag = WordConverter.convert(content, url, link)
  next tag
end

converter.add(["x"], ["page.section-table"]) do |element|
  content = apply(element, "page.section-table").to_s
  url = converter.url_prefix + DICTIONARY_URL
  tag = WordConverter.convert(content, url, false)
  next tag
end

converter.add(["xn"], ["page", "page.section-table"]) do |element|
  content = apply(element, "page").to_s
  url = converter.url_prefix + DICTIONARY_URL
  tag = WordConverter.convert(content, url, false)
  next tag
end

converter.add(["red"], ["page"]) do |element|
  tag = TagBuilder.new("span", "redact")
  tag << "&nbsp;" * element.attribute("length").to_s.to_i
  next tag
end

converter.add(["sup", "sub"], ["page", "page.section-table"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["h"], ["page", "page.section-table"]) do |element|
  tag = TagBuilder.new("span", "hairia")
  tag << apply(element, "page")
  next tag
end

converter.add(["k"], ["page", "page.section-table"]) do |element|
  tag = TagBuilder.new("span", "japanese")
  tag << apply(element, "page")
  next tag
end

converter.add(["i"], ["page", "page.section-table"]) do |element|
  tag = pass_element(element, "page")
  next tag
end

converter.add(["fl"], ["page"]) do |element|
  tag = TagBuilder.new("span", "foreign")
  tag << apply(element, "page")
  next tag
end

converter.add(["small"], ["page"]) do |element|
  tag = TagBuilder.new("span", "small")
  tag << apply(element, "page")
  next tag
end

converter.add(["br"], ["page"]) do |element|
  tag = pass_element(element, "page", false)
  next tag
end

converter.set_default_text do |text|
  string = text.to_s.clone
  string.gsub!("、", "、 ")
  string.gsub!("。", "。 ")
  string.gsub!("「", " 「")
  string.gsub!("」", "」 ")
  string.gsub!("『", " 『")
  string.gsub!("』", "』 ")
  string.gsub!("〈", " 〈")
  string.gsub!("〉", "〉 ")
  string.gsub!(/(、|。)\s+(」|』)/){$1 + $2}
  string.gsub!(/(」|』|〉)\s+(、|。|,|\.)/){$1 + $2}
  string.gsub!(/(\(|「|『)\s+(「|『)/){$1 + $2}
  string.gsub!(/(^|>)\s+(「|『)/){$1 + $2}
  next string
end