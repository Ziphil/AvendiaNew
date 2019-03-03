# coding: utf-8


PREFIX_CONJUGATIONS = {
  "du" => ["du", {:ja => "否", :en => "NEG"}],
  "a" => ["a", {:ja => "形", :en => "ADJ"}],
  "o" => ["o", {:ja => "副", :en => "ADV"}],
  "e" => ["e", {:ja => "副", :en => "ADV"}],
  "i" => ["i", {:ja => "非動修", :en => "NVM"}]
}
SUFFIX_CONJUGATIONS = {
  "a" => ["a", {:ja => "現", :en => "PRS"}],
  "e" => ["e", {:ja => "過", :en => "PST"}],
  "i" => ["i", {:ja => "未", :en => "FUT"}],
  "o" => ["o", {:ja => "通", :en => "DCH"}],
  "f" => ["f", {:ja => "開.自", :en => "INCP.INTR"}],
  "c" => ["c", {:ja => "経.自", :en => "PROG.INTR"}],
  "k" => ["k", {:ja => "完.自", :en => "PERF.INTR"}],
  "t" => ["t", {:ja => "継.自", :en => "CONT.INTR"}],
  "p" => ["p", {:ja => "終.自", :en => "TERM.INTR"}],
  "s" => ["s", {:ja => "無.自", :en => "INDF.INTR"}],
  "v" => ["v", {:ja => "開.他", :en => "INCP.TR"}],
  "q" => ["q", {:ja => "経.他", :en => "PROG.TR"}],
  "g" => ["g", {:ja => "完.他", :en => "PERF.TR"}],
  "d" => ["d", {:ja => "継.他", :en => "CONT.TR"}],
  "b" => ["b", {:ja => "終.他", :en => "TERM.TR"}],
  "z" => ["z", {:ja => "無.他", :en => "INDF.TR"}]
}
FIXED_NAMES = {
  "a" => ["a", {:ja => "主", :en => "NOM"}],
  "e" => ["e", {:ja => "対", :en => "ACC"}],
  "ca" => ["ca", {:ja => "与", :en => "DAT"}],
  "zi" => ["zi", {:ja => "奪", :en => "ABL"}],
  "li" => ["li", {:ja => "被", :en => "PAT"}],
  "pa" => ["pa", {:ja => "疑", :en => "INT"}],
  "kin" => ["kin", {:ja => "節", :en => "COMP"}],
  "'n" => ["'n", {:ja => "節", :en => "COMP"}]
}

converter.add(["gloss"], ["page.xl.li"]) do |element|
  this = ""
  this << Tag.build("ul") do |this|
    this << Tag.build("li", "gloss") do |this|
      this << apply(element, "page.gloss")
    end
  end
  next this
end

converter.add(["gloss"], ["page"]) do |element|
  this = ""
  this << Tag.build("div", "gloss") do |this|
    this << apply(element, "page.gloss")
  end
  next this
end

converter.add(["li"], ["page.gloss"]) do |element|
  this = ""
  this << Tag.build("div", "word") do |this|
    if element.attribute("auto")
      name_query = element.attribute("auto").value
      FIXED_NAMES.each do |code, (name, kind)|
        if name_query == code
          element << Element.build("sh") do |element|
            element << Element.build("x") do |element|
              element << Text.new(name, true, nil, false)
            end
          end
          element << Element.build("ex") do |element|
            element << Element.build("mph") do |element|
              element << Text.new(kind[converter.language], true, nil, false)
            end
          end
        end
      end
    end
    if element.attribute("punc")
      punctuation = element.attribute("punc").value
      element << Element.build("sh") do |element|
        element << Element.build("xn") do |element|
          element << Text.new(punctuation, true, nil, false)
        end
      end
    end
    this << apply(element, "page.gloss.li")
  end
  next this
end

converter.add(nil, ["page.gloss"]) do |text|
  if text.previous_sibling && text.next_sibling
    previous_sibling = text.previous_sibling
    next_sibling = text.next_sibling
    if previous_sibling.is_a?(Element) && previous_sibling.attribute("punc")&.value =~ /(\[|«|“)$/
      string = ""
    elsif next_sibling.is_a?(Element) && next_sibling.attribute("punc")&.value =~ /^(\.|,|!|\?)/
      string = ""
    else
      string = text.to_s
    end
  else
    string = ""
  end
  next string
end

converter.add(["sh", "ex"], ["page.gloss.li"]) do |element|
  this = ""
  this << Tag.build("div") do |this|
    case element.name
    when "sh"
      this.class = "name"
    when "ex"
      this.class = "explanation"
    end
    this << apply(element, "page")
    if element.parent.attribute("conj")
      conjugation_query = element.parent.attribute("conj").value
      prefix_query, suffix_query = conjugation_query.split("-", 2)
      prefix_results, suffix_results = [], []
      PREFIX_CONJUGATIONS.each do |code, (prefix, kind)|
        if index = prefix_query.index(code)
          case element.name
          when "sh"
            prefix_tag = Tag.build("span", "sans") do |this|
              this << prefix
            end
            prefix_results[index] = prefix_tag.to_s + "-"
          when "ex"
            prefix_results[index] = kind[converter.language] + "-"
          end
        end
      end
      SUFFIX_CONJUGATIONS.each do |code, (suffix, kind)|
        if index = suffix_query.index(code)
          case element.name
          when "sh"
            suffix_tag = Tag.build("span", "sans") do |this|
              this << suffix
            end
            suffix_results[index] = "-" + suffix_tag.to_s
          when "ex"
            suffix_results[index] = "-" + kind[converter.language]
          end
        end
      end
      prefix_addition = prefix_results.join
      suffix_addition = suffix_results.join
      if element.name == "ex"
        prefix_morpheme_tag = Tag.build("span", "morpheme") do |this|
          this << prefix_addition
        end
        suffix_morpheme_tag = Tag.build("span", "morpheme") do |this|
          this << suffix_addition
        end
        prefix_addition = prefix_morpheme_tag.to_s
        suffix_addition = suffix_morpheme_tag.to_s
      end
      this.at(0) << prefix_addition
      this.at(-1) << suffix_addition
    end
  end
  next this
end

converter.add(["mph"], ["page"]) do |element|
  this = ""
  this << Tag.build("span", "morpheme") do |this|
    this << apply(element, "page")
  end
  next this
end