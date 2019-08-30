# coding: utf-8


PDF_MESSAGE = "ブラウザが PDF ファイルの表示に対応していない場合は、以下のリンクから PDF ファイルを直接ダウンロードしてください。"

parser.register_macro("ref") do |attributes, children_list|
  this = Nodes[]
  if attributes["c"]
    codepoint = attributes["c"]
    this << Text.new("&##{codepoint};", true, nil, true)
  elsif attributes["n"]
    name = attributes["n"]
    this << Text.new("&#{name};", true, nil, true)
  end
  next this
end

parser.register_macro("math-pdf") do |attributes, children_list|
  this = Nodes[]
  number = attributes["number"]
  this << Element.build("h1") do |this|
    this << ~"閲覧"
  end
  this << Element.build("pdf") do |this|
    this["src"] = "../../file/mathematics_diary/#{number}.pdf"
  end
  this << Element.build("h1") do |this|
    this << ~"PDF ダウンロード"
  end
  this << Element.build("p") do |this|
    this << ~PDF_MESSAGE
  end
  this << Element.build("form") do |this|
    this << Element.build("a") do |this|
      this["class"] = "form"
      this["href"] = "../../file/mathematics_diary/#{number}.pdf"
      this << ~"ダウンロード"
    end
  end
  next this
end