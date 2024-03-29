﻿# coding: utf-8


TEMPLATE = File.read(File.join(BASE_PATH, "template/template.html"))

NAMES = {
  :title => {:ja => "Avendia", :en => "Avendia"},
  :caption => {:ja => "人工言語シャレイア語", :en => "Sheleian Constructed Language"},
  :top => {:ja => "トップ", :en => "Top"},
  :conlang => {:ja => "シャレイア語", :en => "Shaleian"},
  :conlang_grammer => {:ja => "文法書", :en => "Grammar"},
  :conlang_course => {:ja => "入門書", :en => "Introduction"},
  :conlang_database => {:ja => "データベース", :en => "Database"},
  :conlang_culture => {:ja => "文化", :en => "Culture"},
  :conlang_work => {:ja => "創作", :en => "Works"},
  :conlang_translation => {:ja => "翻訳", :en => "Translations"},
  :conlang_theory => {:ja => "シャレイア語論", :en => "Studies"},
  :conlang_document => {:ja => "資料", :en => "Documents"},
  :conlang_table => {:ja => "一覧表", :en => "Tables"},
  :application => {:ja => "自作ソフト", :en => "Softwares"},
  :application_download => {:ja => "ダウンロード", :en => "Download"},
  :application_web => {:ja => "Web アプリ", :en => "Web application"},
  :diary => {:ja => "日記", :en => "Diary"},
  :diary_conlang => {:ja => "シャレイア語", :en => "Shaleian"},
  :diary_language => {:ja => "自然言語", :en => "Languages"},
  :diary_mathematics => {:ja => "数学", :en => "Mathematics"},
  :diary_application => {:ja => "プログラミング", :en => "Programming"},
  :diary_game => {:ja => "ゲーム制作", :en => "Game"},
  :other => {:ja => "その他", :en => "Others"},
  :other_mathematics => {:ja => "数学", :en => "Mathematics"},
  :other_language => {:ja => "自然言語", :en => "Languages"},
  :other_tsolitaire => {:ja => "Tsolitaire", :en => "Tsolitaire"},
  :other_other => {:ja => "その他", :en => "Others"},
  :error => {:ja => "エラー", :en => "Error"},
  :error_error => {:ja => "エラー", :en => "Error"}
}
FOREIGN_LANGUAGES = {:ja => :en, :en => :ja}
LANGUAGE_NAMES = {:ja => "日本語", :en => "English"}
LATEST_VERSION_REGEX = /(5\s*代\s*5\s*期|S\s*代|Version\s*5\.5|Version\s*S)/
DICTIONARY_URL = "https://dic.ziphil.com"

INLINE_ELEMENT_NAMES = ["x", "xn", "a"]

converter.add(["page"], [""]) do |element|
  path, language = converter.path, converter.language
  foreign_language = FOREIGN_LANGUAGES[language]
  deepness = converter.deepness
  virtual_deepness = (path =~ /index\.zml$/) ? deepness - 1 : deepness
  title = ""
  navigation_string, header_string, main_string = "", "", ""
  navigation_string << Tag.build("ul", "breadcrumb") do |this|
    this["itemscope"] = "itemscope"
    this["itemtype"] = "https://schema.org/BreadcrumbList"
    if virtual_deepness >= -1
      this << Tag.build_breadcrumb_item(1) do |item_tag, link_tag, name_tag|
        link_tag["href"] = "../" * deepness
        name_tag << NAMES[:top][language]
      end
    end
    if virtual_deepness >= 0
      first_category = path.split("/")[-deepness - 1]
      this << Tag.build_breadcrumb_item(2) do |item_tag, link_tag, name_tag|
        link_tag["href"] = "../../" + first_category
        name_tag << NAMES[first_category.intern][language]
      end
    end
    if virtual_deepness >= 1
      second_category = path.split("/")[-deepness]
      united_category = first_category + "_" + second_category
      this << Tag.build_breadcrumb_item(3) do |item_tag, link_tag, name_tag|
        link_tag["href"] = "../" + second_category
        name_tag << NAMES[united_category.intern][language]
      end
    end
    if virtual_deepness >= 2
      converted_path = path.match(/([0-9a-z\-]+)\.zml/).to_a[1].to_s
      converted_path += (element.attribute("link")&.value == "c") ? ".cgi" : ".html"
      name_element = element.elements.to_a("name").first
      title = name_element.inner_text(true).gsub("\"", "&quot;")
      this << Tag.build_breadcrumb_item(4) do |item_tag, link_tag, name_tag|
        link_tag["href"] = converted_path
        name_tag << apply(name_element, "page")
      end
    end
  end
  navigation_string << apply(element, "navigation")
  header_string << apply(element, "header")
  main_string << apply(element, "page")
  page_title = [title, NAMES[:title][language]].reject(&:empty?).join(" — ")
  result = TEMPLATE.gsub(/#\{(.*?)\}/){instance_eval($1)}.gsub(/\r/, "")
  next result
end

converter.add(["page"], ["change-log"]) do |element|
  this = ""
  path, language = converter.path, converter.language
  deepness = converter.deepness
  virtual_deepness = (path =~ /index\.zml$/) ? deepness - 1 : deepness
  this << Tag.build("ul", "breadcrumb") do |this|
    if virtual_deepness >= -1
      this << Tag.build("li") do |this|
        this << ""
      end
    end
    if virtual_deepness >= 0
      first_category = path.split("/")[-deepness - 1]
      this << Tag.build("li") do |this|
        this << Tag.build("span") do |this|
          if virtual_deepness == 0
            this.name = "a"
            this["href"] = first_category
          end
          this << NAMES[first_category.intern][language]
        end
      end
    end
    if virtual_deepness >= 1
      second_category = path.split("/")[-deepness]
      united_category = first_category + "_" + second_category
      this << Tag.build("li") do |this|
        this << Tag.build("span") do |this|
          if virtual_deepness == 1
            this.name = "a"
            this["href"] = first_category + "/" + second_category
          end
          this << NAMES[united_category.intern][language]
        end
      end
    end
    if virtual_deepness >= 2
      converted_path = path.match(/([0-9a-z\-]+)\.zml/).to_a[1].to_s + ".html"
      name_element = element.elements.to_a("name").first
      this << Tag.build("li") do |this|
        this << Tag.build("span") do |this|
          if virtual_deepness == 2
            this.name = "a"
            this["href"] = first_category + "/" + second_category + "/" + converted_path
          end
          this << apply(name_element, "page")
        end
      end
    end
  end
  next this
end

converter.add(["ver"], ["navigation"]) do |element|
  this = ""
  this << Tag.build("div") do |this|
    if element.text == "*" || element.text =~ LATEST_VERSION_REGEX
      this.class = "version"
      variables[:latest] = true
    else
      this.class = "version caution"
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(nil, ["navigation"]) do |text|
  next ""
end

converter.add(["import-script"], ["header"]) do |element|
  this = ""
  this << Tag.build("script") do |this|
    inner_text = element.inner_text
    if inner_text.empty?
      this["src"] = converter.url_prefix + File.join("program/script", element.attribute("src").to_s)
    else
      this << inner_text
    end
  end
  next this + "\n"
end

converter.add(["base"], ["header"]) do |element|
  this = ""
  this << Tag.build("base") do |this|
    this["href"] = element.attribute("href").to_s
  end
  next this + "\n"
end

converter.add(nil, ["header"]) do |text|
  next ""
end

converter.add(["pb"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "index-container") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["hb"], ["page"]) do |element|
  this = ""
  this << Tag.build("h1") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["ab", "abo", "aba", "abd"], ["page"]) do |element|
  this = ""
  this << Tag.build do |this|
    case element.name
    when "ab"
      this.name, this.class = "a", "index"
      annotation = nil
    when "abo"
      this.name, this.class = "a", "index old"
      annotation = "old"
    when "aba"
      this.name, this.class = "a", "index ancient"
      annotation = "ancient"
    when "abd"
      this.name, this.class = "div", "index"
      annotation = nil
    end
    element.attributes.each_attribute do |attribute|
      if attribute.name == "date"
        this << Tag.build("span", "date") do |this|
          if element.attribute("date").value =~ /^\d+$/
            this << Tag.build("span", "hairia") do |this|
              this << element.attribute("date").to_s
            end
          else
            this << element.attribute("date").to_s
          end
        end
      else
        this[attribute.name] = attribute.to_s
      end
    end
    this << Tag.build("span", "content") do |this|
      this << apply(element, "page")
    end
    if annotation
      this << Tag.build("span", "annotation") do |this|
        this << annotation
      end
    end 
  end
  next this
end

converter.add(["h1", "h2"], ["page"]) do |element|
  this = ""
  this << Tag.build(element.name) do |this|
    element.attributes.each_attribute do |attribute|
      if attribute.name == "number"
        this["id"] = element.attribute("number").to_s
        this << Tag.build("span", "number") do |this|
          this << element.attribute("number").to_s
        end
      else
        this[attribute.name] = attribute.to_s
      end
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["p"], ["page"]) do |element|
  this = ""
  this << Tag.build("p") do |this|
    this << apply(element, "page")
    if element.attribute("par")
      this.at_head << Tag.build("span", "paragraph") do |this|
        this["data-number"] = element.attribute("par").to_s
      end
    end
    if element.attribute("name")
      this.at_head << Tag.build("span", "name") do |this|
        this << element.attribute("name").to_s
      end
    end
  end
  next this
end

converter.add(["label"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "label") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["img"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "img-wrapper") do |this|
    this << Tag.build("img", nil, false) do |this|
      this["alt"] = ""
      element.attributes.each_attribute do |attribute|
        this[attribute.name] = attribute.to_s
      end
      this << apply(element, "page")
    end
  end
  next this
end

converter.add(["a"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["ae"], ["page"]) do |element|
  this = ""
  this << Tag.build("a") do |this|
    element.attributes.each_attribute do |attribute|
      this[attribute.name] = attribute.to_s
    end
    this["target"] = "_blank"
    this["rel"] = "noopener noreferrer"
    this << apply(element, "page")
  end
  next this
end

converter.add(["an"], ["page"]) do |element|
  this = ""
  this << Tag.build("a", "normal") do |this|
    element.attributes.each_attribute do |attribute|
      this[attribute.name] = attribute.to_s
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["xl"], ["page"]) do |element|
  this = ""
  this << Tag.build("ul", "conlang") do |this|
    this << apply(element, "page.xl")
  end
  next this
end

converter.add(["li"], ["page.xl"]) do |element|
  this = ""
  this << Tag.build("li") do |this|
    this << apply(element, "page.xl.li")
  end
  next this
end

converter.add(["sh"], ["page.xl.li"]) do |element|
  this = ""
  this << apply(element, "page")
  next this
end

converter.add(["ja"], ["page.xl.li"]) do |element|
  this = ""
  this << Tag.build("ul") do |this|
    this << Tag.build("li") do |this|
      this << apply(element, "page")
    end
  end
  next this
end

converter.add(nil, ["page.xl.li"]) do |text|
  next ""
end

converter.add(["el"], ["page"]) do |element|
  this = ""
  this << Tag.build("table", "list") do |this|
    this << apply(element, "page.el")
  end
  next this
end

converter.add(["li"], ["page.el"]) do |element|
  this = ""
  this << Tag.build("tr") do |this|
    this << apply(element, "page.el.li")
  end
  next this
end

converter.add(["et", "ed"], ["page.el.li"]) do |element|
  this = ""
  this << Tag.build("td") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["trans"], ["page"]) do |element|
  this = ""
  this << Tag.build("table", "translation") do |this|
    this << apply(element, "page.trans")
  end
  next this
end

converter.add(["li"], ["page.trans"]) do |element|
  this = ""
  this << Tag.build("tr") do |this|
    this << apply(element, "page.trans.li")
  end
  next this
end

converter.add(["ja", "sh"], ["page.trans.li"]) do |element|
  this = ""
  this << Tag.build("td") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["spch"], ["page"]) do |element|
  this = ""
  name_element = element.elements.to_a("name").first
  this << Tag.build("div", "speech-wrapper") do |this|
    if element.attribute("inv")
      this.class << " invert" 
    end
    this << Tag.new("div", "border")
    this << Tag.build("div", "speech") do |this|
      this << Tag.build("div", "name") do |this|
        this << apply(name_element, "page")
      end
      this << Tag.build("div", "content") do |this|
        this << apply(element, "page")
      end
    end
  end
  next this
end

converter.add(["section-table"], ["page"]) do |element|
  this = ""
  this << Tag.build("ul", "section-table") do |this|
    section_tag = Tag.new("li")
    subsection_tag = Tag.new("ul")
    element.each_xpath("/page/*[name() = 'h1' or name() = 'h2']") do |inner_element|
      case inner_element.name
      when "h1"
        unless section_tag.content.empty?
          section_tag << subsection_tag unless subsection_tag.content.empty?
          this << section_tag
        end
        section_tag = Tag.build("li") do |this|
          if inner_element.attribute("id")
            this << Tag.build("a") do |this|
              this["href"] = "#" + inner_element.attribute("id").to_s
              this << apply(inner_element, "page.section-table")
            end
          else
            this << apply(inner_element, "page.section-table")
          end
        end
        subsection_tag = Tag.new("ul")
      when "h2"
        subsection_tag << Tag.build("li") do |this|
          if inner_element.attribute("number")
            this << Tag.build("span", "number") do |this|
              this << inner_element.attribute("number").to_s
            end
            this << Tag.build("a") do |this|
              this["href"] = "#" + inner_element.attribute("number").to_s
              this << apply(inner_element, "page.section-table")
            end
          elsif inner_element.attribute("id")
            this << Tag.build("a") do |this|
              this["href"] = "#" + inner_element.attribute("id").to_s
              this << apply(inner_element, "page.section-table")
            end
          else
            this << apply(inner_element, "page.section-table")
          end
        end
      end
    end
    section_tag << subsection_tag unless subsection_tag.content.empty?
    this << section_tag
  end
  next this
end

converter.add(["change-log"], [//]) do |element|
  this = ""
  language = converter.language
  size = element.attribute("size")&.to_s&.to_i
  log_path = CONFIG.log_path(language)
  log_entries = File.read(log_path).lines[0...size]
  this << Tag.build("ul", "change-log") do |this|
    log_entries.each do |log_entry|
      date_string, content = log_entry.split(/\s*;\s*/, 2)
      this << Tag.build("li") do |this|
        this << Tag.build("span", "date") do |this|
          this << date_string
        end
        this << content
      end
    end
  end
  next this
end

converter.add(["ul", "ol"], ["page"]) do |element|
  this = pass_element(element, "page.ul")
  next this
end

converter.add(["li"], ["page.ul"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["side"], ["page"]) do |element|
  this = ""
  if !element.get_elements("table").empty?
    this << Tag.build("div", "table-wrapper") do |this|
      this << apply(element, "page-wrapped")
    end
  elsif !element.get_elements("img").empty?
    this << Tag.build("div", "img-wrapper") do |this|
      this << apply(element, "page-wrapped")
    end
  end
  next this
end

converter.add(["table"], ["page", "page-wrapped"]) do |element, scope|
  this = ""
  span_data = Hash.new{|h, s| h[s] = {}}
  element.each_xpath("tr").with_index do |row_element, row_index|
    cell_index, new_cell_elements = 0, []
    row_element.elements.each_with_index do |cell_element|
      row_span = (cell_element.attribute("row") || 1).to_s.to_i
      column_span = (cell_element.attribute("col") || 1).to_s.to_i
      if addition_size = span_data[row_index][cell_index]
        addition_size.times do
          new_cell_elements << Element.new("td-dummy")
        end
        cell_index += addition_size
      end
      (1..(row_span - 1)).each do |i|
        span_data[row_index + i][cell_index] = column_span
      end
      new_cell_elements << cell_element
      (column_span - 1).times do
        new_cell_elements << Element.new("td-dummy")
      end
      cell_index += column_span
    end
    row_element.delete_if{true}
    new_cell_elements.each do |new_cell_element|
      row_element.add(new_cell_element)
    end
  end
  column_size = element.each_xpath("tr").map{|s| s.elements.size}.max
  head_column_sizes = element.each_xpath("tr").map do |row_element|
    array = row_element.elements.map do |cell_element|
      if cell_element.name == "th" || cell_element.name == "thl"
        next 1
      else
        next 0
      end
    end
    next array.sum
  end
  head_row_size = head_column_sizes.take_while{|s| s >= column_size}.size
  head_column_size = head_column_sizes.min
  element.each_xpath("tr").with_index do |row_element, row_index|
    if row_index == head_row_size - 1
      row_element.elements.each do |cell_element|
        cell_element["line"] ||= ""
        cell_element["line"] += " bottom"
      end
    end
    row_element.elements.each_with_index do |cell_element, column_index|
      if column_index == head_column_size - 1
        cell_element["line"] ||= ""
        cell_element["line"] += " right"
      end
    end
  end
  this << pass_element(element, "page.table")
  unless scope.include?("wrapped")
    new_this = ""
    new_this << Tag.build("div", "table-wrapper") do |new_this|
      new_this << this
    end
    this = new_this
  end
  next this
end

converter.add(["caption"], ["page.table"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["tr"], ["page.table"]) do |element|
  this = pass_element(element, "page.table.tr")
  next this
end

converter.add(["th", "thl", "td", "td-dummy"], ["page.table.tr"]) do |element|
  this = ""
  this << Tag.build do |this|
    case element.name
    when "th", "thl"
      this.name = "th"
    when "td", "td-dummy"
      this.name = "td"
    end
    if element.attribute("row")
      this["rowspan"] = element.attribute("row").to_s
    end
    if element.attribute("col")
      this["colspan"] = element.attribute("col").to_s
    end
    if element.attribute("line")
      this.class ||= ""
      this.class << element.attribute("line").to_s.split(" ").map{|s| s + "-line"}.join(" ")
    end
    if element.name == "td-dummy"
      this["style"] = "display: none;"
    end
    this << apply(element, "page")
  end
  next this
end

converter.add(["form"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["input"], ["page"]) do |element|
  this = pass_element(element, "page", false)
  next this
end

converter.add(["textarea"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["pdf"], ["page"]) do |element|
  this = ""
  this << Tag.build("object", "pdf") do |this|
    this["data"] = element.attribute("src").to_s + "#view=FitH&amp;statusbar=0&amp;toolbar=0&amp;navpanes=0&amp;messages=0"
    this["type"] = "application/pdf"
  end
  next this
end

converter.add(["slide"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "slide") do |this|
    this << Tag.build("script", "speakerdeck-embed") do |this|
      this["async"] = "async"
      this["data-id"] = element.attribute("id").to_s
      this["data-ratio"] = "1.33333333333333"
      this["src"] = "http://speakerdeck.com/assets/embed.js"
    end
  end
  next this
end

converter.add(["youtube"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "youtube") do |this|
    this << Tag.build("iframe") do |this|
      this["allow"] = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      this["allowfullscreen"] = "allowfullscreen"
      this["frameborder"] = "0"
      this["src"] = "https://www.youtube.com/embed/" + element.attribute("id").to_s
    end
  end
  next this
end

converter.add(["pre", "samp"], ["page"]) do |element|
  this = ""
  raw_string = element.texts.map{|s| s.to_s}.join.gsub(/\A\s*?\n/, "")
  indent_size = raw_string.match(/\A(\s*?)\S/)[1].length
  string = raw_string.rstrip.deindent
  this << Tag.build("div", "code-wrapper") do |this|
    this << Tag.build("div", "code-inner-wrapper") do |this|
      this << Tag.build("table") do |this|
        case element.name
        when "pre"
          this.class = "code"
        when "samp"
          this.class = "sample"
        end
        this << "\n"
        string.each_line.with_index do |line, number|
          this << " " * indent_size
          this << Tag.build("tr") do |this|
            if element.name == "pre" && !element.attribute("simple")
              this << Tag.build("td", "number") do |this|
                this["data-number"] = (number + 1).to_s
              end
            end
            this << Tag.build("td") do |this|
              if line =~ /^\s*$/
                this << " "
              else
                this << line.chomp
              end
            end
          end
          this << "\n"
        end
        this << " " * (indent_size - 2)
      end
    end
  end
  next this
end

converter.add(["c", "m"], ["page", "page.section-table"]) do |element|
  this = ""
  this << Tag.build("span") do |this|
    case element.name
    when "c"
      this.class = "code"
    when "m"
      this.class = "monospace"
    end
    element.children.each do |child|
      case child
      when Element
        this << convert_element(child, "page")
      when Text
        this << child.to_s
      end
    end
  end
  next this
end

converter.add(["birthday"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "birthday") do |this|
    this << apply(element, "page.birthday")
  end
  next this
end

converter.add(["date"], ["page.birthday"]) do |element|
  this = ""
  this << Tag.build("div", "date") do |this|
    this << element.to_s
  end
  next this
end

converter.add(["message"], ["page.birthday"]) do |element|
  this = ""
  this << Tag.build("div", "message") do |this|
    this << element.to_s
  end
  next this
end

converter.add(["special"], ["page"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["x"], ["page"]) do |element|
  this = ""
  content = apply(element, "page").to_s
  link = !!variables[:latest] && converter.path =~ /conlang\/.+\/\d+(\-\w{2})?\.zml/
  this << WordConverter.convert(content, DICTIONARY_URL, link)
  next this
end

converter.add(["x"], ["page.section-table"]) do |element|
  this = ""
  content = apply(element, "page.section-table").to_s
  this << WordConverter.convert(content, DICTIONARY_URL, false)
  next this
end

converter.add(["xn"], ["page", "page.section-table"]) do |element|
  this = ""
  content = apply(element, "page").to_s
  this << WordConverter.convert(content, DICTIONARY_URL, false)
  next this
end

converter.add(["lys"], ["page"]) do |element|
  this = ""
  this << Tag.new("span", "lyrics-space")
  next this
end

converter.add(["red"], ["page"]) do |element|
  this = ""
  title = element.attribute("title")&.to_s
  length = element.attribute("length")&.to_s&.to_i
  if !length && title
    length = title.chars.map{|s| Unicode::DisplayWidth.of(s) * 1.5}.sum.to_i
  end
  this << Tag.build("span", "redact") do |this|
    this << "&nbsp;" * (length || 0)
    if title
      this["title"] = title
    end
  end
  next this
end

converter.add(["sup", "sub"], ["page", "page.section-table"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["div", "span"], [//]) do |element, scope|
  this = pass_element(element, scope)
  next this
end

converter.add(["h"], ["page", "page.section-table"]) do |element|
  this = ""
  this << Tag.build("span", "hairia") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["k"], ["page", "page.section-table"]) do |element|
  this = ""
  this << Tag.build("span", "japanese") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["i"], ["page", "page.section-table"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["fl"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "foreign") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["small"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "small") do |this|
    this << apply(element, "page")
  end
  next this
end

converter.add(["br"], ["page"]) do |element|
  this = pass_element(element, "page", false)
  next this
end

converter.add_default(nil) do |text|
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
  unless text.previous_sibling&.is_a?(Element) && INLINE_ELEMENT_NAMES.include?(text.previous_sibling&.name)
    string.gsub!(/^\s+(「|『)/){$1}
  end
  unless text.next_sibling&.is_a?(Element) && INLINE_ELEMENT_NAMES.include?(text.next_sibling&.name)
    string.gsub!(/(」|』)\s+$/){$1}
  end
  if text.previous_sibling
    previous_sibling = text.previous_sibling
    if previous_sibling.is_a?(Element) && previous_sibling.name == "label"
      string.gsub!(/^\s+/, "")
    end
  end
  next string
end