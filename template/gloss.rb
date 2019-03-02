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
  tag = Tag.new("ul")
  item_tag = Tag.new("li", "gloss")
  item_tag << apply(element, "page.gloss")
  tag << item_tag
  next tag
end

converter.add(["gloss"], ["page"]) do |element|
  tag = Tag.new("div", "gloss")
  tag << apply(element, "page.gloss")
  next tag
end

converter.add(["li"], ["page.gloss"]) do |element|
  tag = Tag.new("div", "word")
  if element.attribute("auto")
    name_query = element.attribute("auto").value
    FIXED_NAMES.each do |code, (name, kind)|
      if name_query == code
        name_element = Element.new("sh")
        shaleia_element = Element.new("x")
        explanation_element = Element.new("ex")
        morpheme_element = Element.new("mph")
        shaleia_element << Text.new(name, true, nil, false)
        name_element << shaleia_element
        morpheme_element << Text.new(kind[converter.language], true, nil, false)
        explanation_element << morpheme_element
        element << name_element
        element << explanation_element
      end
    end
  end
  if element.attribute("punc")
    punctuation = element.attribute("punc").value
    name_element = Element.new("sh")
    shaleia_element = Element.new("xn")
    shaleia_element << Text.new(punctuation, true, nil, false)
    name_element << shaleia_element
    element << name_element
  end
  tag << apply(element, "page.gloss.li")
  next tag
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
  case element.name
  when "sh"
    tag = Tag.new("div", "name")
  when "ex"
    tag = Tag.new("div", "explanation")
  end
  tag << apply(element, "page")
  if element.parent.attribute("conj")
    conjugation_query = element.parent.attribute("conj").value
    prefix_query, suffix_query = conjugation_query.split("-", 2)
    prefix_results, suffix_results = [], []
    PREFIX_CONJUGATIONS.each do |code, (prefix, kind)|
      if index = prefix_query.index(code)
        case element.name
        when "sh"
          prefix_tag = Tag.new("span", "sans")
          prefix_tag << prefix
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
          suffix_tag = Tag.new("span", "sans")
          suffix_tag << suffix
          suffix_results[index] = "-" + suffix_tag.to_s
        when "ex"
          suffix_results[index] = "-" + kind[converter.language]
        end
      end
    end
    prefix_addition = prefix_results.join
    suffix_addition = suffix_results.join
    if element.name == "ex"
      prefix_morpheme_tag = Tag.new("span", "morpheme")
      prefix_morpheme_tag << prefix_addition
      prefix_addition = prefix_morpheme_tag.to_s
      suffix_morpheme_tag = Tag.new("span", "morpheme")
      suffix_morpheme_tag << suffix_addition
      suffix_addition = suffix_morpheme_tag.to_s
    end
    tag.insert(0, prefix_addition)
    tag.insert(-1, suffix_addition)
  end
  next tag
end

converter.add(["mph"], ["page"]) do |element|
  tag = Tag.new("span", "morpheme")
  tag << apply(element, "page")
  next tag
end