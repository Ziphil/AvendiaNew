# coding: utf-8


parser.register_math_macro("m") do |attributes, children_list|
  this = Nodes[]
  this << Element.build("math-inline") do |this|
    this << children_list.first
  end
  next this
end

parser.register_math_macro("mb") do |attributes, children_list|
  this = Nodes[]
  this << Element.build("math-block") do |this|
    this << children_list.first
  end
  next this
end