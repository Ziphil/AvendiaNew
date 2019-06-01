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

parser.register_macro("lig") do |attributes, children_list|
  this = Nodes[]
  children = children_list[0]
  this << Element.build("li") do |this|
    if attributes["auto"]
      name_query = attributes["auto"]
      FIXED_NAMES.each do |code, (name, kind)|
        if name_query == code
          children << Element.build("sh") do |this|
            this << Element.build("x") do |this|
              this << Text.new(name, true, nil, false)
            end
          end
          children << Element.build("ex") do |this|
            this << Element.build("mph") do |this|
              this << Text.new(kind[parser.language], true, nil, false)
            end
          end
        end
      end
    end
    if attributes["punc"]
      punctuation = attributes["punc"]
      this.add_attribute("punc", punctuation)
      children << Element.build("sh") do |this|
        this << Element.build("xn") do |this|
          this << Text.new(punctuation, true, nil, false)
        end
      end
    end
    if attributes["conj"]
      children.each do |child|
        conjugation_query = attributes["conj"]
        prefix_query, suffix_query = conjugation_query.split("-", 2)
        prefix_results, suffix_results = [], []
        PREFIX_CONJUGATIONS.each do |code, (prefix, kind)|
          if index = prefix_query.index(code)
            case child.name
            when "sh"
              prefix_element = Element.build("x") do |this|
                this << ~prefix
              end
              prefix_text = ~"-"
              prefix_results[index] = Nodes[prefix_element, prefix_text]
            when "ex"
              prefix_text = ~(kind[parser.language] + "-")
              prefix_results[index] = Nodes[prefix_text]
            end
          end
        end
        SUFFIX_CONJUGATIONS.each do |code, (suffix, kind)|
          if index = suffix_query.index(code)
            case child.name
            when "sh"
              suffix_element = Element.build("x") do |this|
                this << ~suffix
              end
              suffix_text = ~"-"
              suffix_results[index] = Nodes[suffix_text, suffix_element]
            when "ex"
              suffix_text = ~("-" + kind[parser.language])
              suffix_results[index] = Nodes[suffix_text]
            end
          end
        end
        prefix_nodes = prefix_results.inject(&:+) || Nodes[]
        suffix_nodes = suffix_results.inject(&:+) || Nodes[]
        if child.name == "ex"
          prefix_morpheme_element = Element.build("mph") do |this|
            this << prefix_nodes
          end
          suffix_morpheme_element = Element.build("mph") do |this|
            this << suffix_nodes
          end
          prefix_nodes = prefix_morpheme_element
          suffix_nodes = suffix_morpheme_element
        end
        child.at_first << prefix_nodes
        child.at_last << suffix_nodes
      end
    end
    children.each do |child|
      this << child
    end
  end
  next this
end