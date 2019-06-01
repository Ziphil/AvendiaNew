# coding: utf-8


require 'pp'
require 'delegate'
require 'rexml/document'
include REXML

Encoding.default_external = "UTF-8"
$stdout.sync = true


class PageConverter

  attr_reader :configs

  def initialize(document)
    @document = document
    @configs = {}
    @templates = {}
    @functions = {}
    @default_element_template = lambda{|s| ""}
    @default_text_template = lambda{|s| ""}
  end

  def convert(initial_scope = "")
    result = ""
    result << convert_element(@document.root, initial_scope)
    return result
  end

  def convert_element(element, scope, *args)
    result = nil
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern != nil && element_pattern.any?{|s| s === element.name} && scope_pattern.any?{|s| s === scope}
        result = instance_exec(element, scope, *args, &block)
        break
      end
    end
    return result || @default_element_template.call(element)
  end

  def pass_element(element, scope, close = true)
    tag = Tag.new(element.name, nil, close)
    element.attributes.each_attribute do |attribute|
      tag[attribute.name] = attribute.to_s
    end
    tag << apply(element, scope)
    return tag
  end

  def convert_text(text, scope, *args)
    result = nil
    @templates.each do |(element_pattern, scope_pattern), block|
      if element_pattern == nil && scope_pattern.any?{|s| s === scope}
        result = instance_exec(text, scope, *args, &block)
        break
      end
    end
    return result || @default_text_template.call(text)
  end

  def pass_text(text, scope)
    string = text.to_s
    return string
  end

  def apply(element, scope)
    result = ""
    element.children.each do |child|
      case child
      when Element
        tag = convert_element(child, scope)
        if tag
          result << tag
        end
      when Text
        string = convert_text(child, scope)
        if string
          result << string
        end
      end
    end
    return result
  end

  def call(element, name, *args)
    result = []
    @functions.each do |function_name, block|
      if function_name == name
        result = instance_exec(element, *args, &block)
        break
      end
    end
    return result
  end

  def add(element_pattern, scope_pattern, &block)
    @templates.store([element_pattern, scope_pattern], block)
  end

  def set(name, &block)
    @functions.store(name, block)
  end

  def add_default(element_pattern, &block)
    if element_pattern
      @default_element_template = block
    else
      @default_text_template = block
    end
  end

end