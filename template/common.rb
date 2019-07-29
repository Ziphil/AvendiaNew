# coding: utf-8


TEMPLATE = File.read(BASE_PATH + "/template/template.html")

NAMES = {
  :title => {:ja => "人工言語シャレイア語", :en => "Sheleian Constructed Language"},
  :top => {:ja => "トップ", :en => "Top"},
  :conlang => {:ja => "シャレイア語", :en => "Shaleian"},
  :conlang_grammer => {:ja => "文法書", :en => "Grammar"},
  :conlang_course => {:ja => "入門書", :en => "Introduction"},
  :conlang_database => {:ja => "データベース", :en => "Database"},
  :conlang_culture => {:ja => "文化", :en => "Culture"},
  :conlang_work => {:ja => "創作", :en => "Works"},
  :conlang_translation => {:ja => "翻訳", :en => "Translations"},
  :conlang_theory => {:ja => "シャレイア語論", :en => "Studies"},
  :conlang_document => {:ja => "資料", :en => "Data"},
  :conlang_table => {:ja => "一覧表", :en => "Tables"},
  :application => {:ja => "自作ソフト", :en => "Softwares"},
  :application_download => {:ja => "ダウンロード", :en => "Download"},
  :application_web => {:ja => "Web アプリ", :en => "Web Application"},
  :diary => {:ja => "日記", :en => "Diary"},
  :diary_conlang => {:ja => "シャレイア語", :en => "Shaleian"},
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
LATEST_VERSION_REGEX = /(5\s*代\s*5\s*期|Version\s*5\.5)/
DICTIONARY_URL = "conlang/database/1.cgi"

converter.add(["page"], [""]) do |element|
  path, language = converter.path, converter.language
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
      converter.configs[:latest] = true
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
    this["src"] = converter.url_prefix + "file/script/" + element.attribute("src").to_s
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

converter.add(["change-log"], ["page"]) do |element|
  this = ""
  language = converter.language
  size = element.attribute("size")&.to_s&.to_i
  log_path = WholeAvendiaConverter::LOG_PATHS[language]
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

converter.add(["table"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "table-wrapper") do |this|
    this << pass_element(element, "page.table")
  end
  next this
end

converter.add(["tr"], ["page.table"]) do |element|
  this = pass_element(element, "page.table.tr")
  next this
end

converter.add(["th", "td"], ["page.table.tr"]) do |element|
  this = pass_element(element, "page")
  next this
end

converter.add(["thl"], ["page.table.tr"]) do |element|
  this = ""
  this << Tag.build("th", "left") do |this|
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
  url = converter.url_prefix + DICTIONARY_URL
  link = !!converter.configs[:latest] && converter.path =~ /conlang\/.+\/\d+(\-\w{2})?\.zml/
  this << WordConverter.convert(content, url, link)
  next this
end

converter.add(["x"], ["page.section-table"]) do |element|
  this = ""
  content = apply(element, "page.section-table").to_s
  url = converter.url_prefix + DICTIONARY_URL
  this << WordConverter.convert(content, url, false)
  next this
end

converter.add(["xn"], ["page", "page.section-table"]) do |element|
  this = ""
  content = apply(element, "page").to_s
  url = converter.url_prefix + DICTIONARY_URL
  this << WordConverter.convert(content, url, false)
  next this
end

converter.add(["red"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "redact") do |this|
    this << "&nbsp;" * element.attribute("length").to_s.to_i
  end
  next this
end

converter.add(["sup", "sub"], ["page", "page.section-table"]) do |element|
  this = pass_element(element, "page")
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

converter.add(["ref"], [//]) do |element|
  this = ""
  this << "&#" + element.attribute("p").to_s + ";"
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
  string.gsub!(/(^|>)\s+(「|『)/){$1 + $2}
  next string
end