# coding: utf-8


class Tag

  attr_accessor :name
  attr_accessor :content

  def initialize(name = nil, clazz = nil, close = true)
    @name = name
    @attributes = (clazz) ? {"class" => clazz} : {}
    @content = ""
    @close = close
  end

  def [](key)
    return @attributes[key]
  end

  def []=(key, value)
    @attributes[key] = value
  end

  def class
    return @attributes["class"]
  end

  def class=(clazz)
    @attributes["class"] = clazz
  end

  def <<(content)
    @content << content
  end

  def at_head
    outer_self = self
    delegator = SimpleDelegator.new(outer_self)
    delegator.define_singleton_method(:<<) do |content|
      outer_self.content.sub!(/(\A\s*)/m){$1 + content.to_str}
    end
    return delegator
  end

  def to_s
    result = ""
    if @name
      result << "<"
      result << @name
      @attributes.each do |key, value|
        result << " #{key}=\"#{value}\""
      end
      result << ">"
      result << @content
      if @close
        result << "</"
        result << @name
        result << ">"
      end
    else
      result << @content
    end
    return result
  end

  def to_str
    return self.to_s
  end

  def self.build(name = nil, clazz = nil, close = true, &block)
    tag = Tag.new(name, clazz, close)
    block.call(tag)
    return tag
  end

end


class Element

  def [](key)
    return attribute(key).to_s
  end

  def []=(key, value)
    add_attribute(key, value)
  end

  def inner_text(compress = false)
    text = XPath.match(self, ".//text()").map{|s| s.value}.join("")
    if compress
      text.gsub!(/\r/, "")
      text.gsub!(/\n\s*/, " ")
      text.gsub!(/\s+/, " ")
      text.strip!
    end
    return text
  end

  def each_xpath(*args, &block)
    if block
      XPath.each(self, *args) do |element|
        block.call(element)
      end
    else
      enumerator = Enumerator.new do |yielder|
        XPath.each(self, *args) do |element|
          yielder << element
        end
      end
      return enumerator
    end
  end

  def self.build(name, &block)
    element = Element.new(name)
    block.call(element)
    return element
  end

end


class Parent

  def <<(object)
    if object.is_a?(Nodes)
      object.each do |child|
        add(child)
      end
    else
      add(object)
    end
  end

  def at_first
    outer_self = self
    delegator = SimpleDelegator.new(outer_self)
    delegator.define_singleton_method(:<<) do |object|
      if object.is_a?(Nodes)
        object.reverse_each do |child|
          outer_self.unshift(child)
        end
      else
        outer_self.unshift(object)
      end
    end
    return delegator
  end

  def at_last
    outer_self = self
    delegator = SimpleDelegator.new(outer_self)
    delegator.define_singleton_method(:<<) do |object|
      if object.is_a?(Nodes)
        object.each do |child|
          outer_self.push(child)
        end
      else
        outer_self.push(object)
      end
    end
    return delegator
  end

end


class Nodes < Array

  def <<(object)
    if object.is_a?(Nodes)
      object.each do |child|
        push(child)
      end
    else
      push(object)
    end
  end

  def +(other)
    return Nodes.new(super(other))
  end

end


class String

  def ~
    return Text.new(self, true, nil, true)
  end

  def indent(size)
    inside_code = false
    split_self = self.each_line.map do |line|
      if inside_code 
        if line =~ /^\s*<\/pre>/
          inside_code = false
        end
        next line
      else
        if line =~ /^\s*<pre>/
          inside_code = true
        end
        next " " * size + line
      end
    end
    return split_self.join
  end

  def deindent
    margin = self.scan(/^ +/).map(&:size).min
    return self.gsub(/^ {#{margin}}/, "")
  end

  def deindent!
    margin = self.scan(/^ +/).map(&:size).min
    self.gsub!(/^ {#{margin}}/, "")
  end

end