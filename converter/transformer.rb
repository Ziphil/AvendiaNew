# coding: utf-8


class Transformer

  def initialize(input, path, language)
    @input = input
    @path = path
    @language = language
  end

  def transform
    raise RuntimeError.new("not implemented")
  end

end


class GreekTransformer < Transformer

  LETTERS = {
    "ά" => "ά", "έ" => "έ", "ή" => "ή", "ί" => "ί", "ό" => "ό", "ύ" => "ύ", "ώ" => "ώ", "ΐ" => "ΐ", "ΰ" => "ΰ",
    "Ά" => "Ά", "Έ" => "Έ", "Ή" => "Ή", "Ί" => "Ί", "Ό" => "Ό", "Ύ" => "Ύ", "Ώ" => "Ώ"
  }

  def transform
    chars = @input.chars
    chars.map! do |char|
      next LETTERS.fetch(char, char)
    end
    output = chars.join
    return output
  end

end