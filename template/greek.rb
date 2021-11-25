# coding: utf-8


GREEK_DIACTIRICS = {"a" => "´", "g" => "`", "s" => "᾿", "sa" => "῎", "sg" => "῍", "r" => "῾", "ra" => "῞", "rg" => "῝", "i" => "ι"}

converter.add(["gd"], ["page", "page.section-table"]) do |element|
  this = ""
  diacritic_type = element.attribute("d").to_s
  this << Tag.build("span", "greek") do |this|
    this << Tag.build("span", "char") do |this|
      this << apply(element, "page")
    end
    unless diacritic_type.gsub("i", "") == ""
      this << Tag.build("span", "diacritic") do |this|
        this << GREEK_DIACTIRICS[diacritic_type.gsub("i", "")]
      end
    end
    if diacritic_type.include?("i")
      this << Tag.build("span", "diacritic below") do |this|
        this << GREEK_DIACTIRICS["i"]
      end
    end
  end
  next this
end