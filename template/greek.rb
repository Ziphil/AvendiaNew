# coding: utf-8


GREEK_DIACTIRICS = {"a" => "´", "g" => "`", "sa" => "῎", "sg" => "῍", "ra" => "῞", "rg" => "῝"}

converter.add(["gt"], ["page"]) do |element|
  this = ""
  diacritic_type = element.attribute("d").to_s
  this << Tag.build("span", "greek") do |this|
    this << Tag.build("span", "char") do |this|
      this << apply(element, "page")
    end
    this << Tag.build("span", "diacritic") do |this|
      this << GREEK_DIACTIRICS[diacritic_type]
    end
  end
  next this
end