# coding: utf-8


module ShaleiaUtilities

  TENSES = {"現在時制" => "a", "過去時制" => "e", "未来時制" => "i", "通時時制" => "o"}
  INTRANSITIVE_ASPECTS = {"開始相, 自動詞" => "f", "経過相, 自動詞" => "c", "完了相, 自動詞" => "k", "継続相, 自動詞" => "t", "終了相, 自動詞" => "p", "無相, 自動詞" => "s"}
  TRANSITIVE_ASPECTS = {"開始相, 他動詞" => "v",  "経過相, 他動詞" => "q", "完了相, 他動詞" => "g", "継続相, 他動詞" => "d", "終了相, 他動詞" => "b", "無相, 他動詞" => "z"}
  VERB_PREFIXES = {"形容詞" => "a", "副詞" => "o"}
  ADVERB_PREFIXES = {"副詞" => "e"}
  PARTICLE_PREFIXES = {"非動詞修飾" => "i"}
  NEGATION_PREFIXES = {"否定" => "du"}
  CATEGORIES = {"名" => "noun", "動" => "verb", "形" => "adjective", "副" => "adverb", "助" => "preposition", "接" => "conjunction", "間" => "interjection", "縮" => "contraction"}
  ASPECTS = {}.merge(INTRANSITIVE_ASPECTS).merge(TRANSITIVE_ASPECTS)

  USED_CONTENT_ALPHABETS = {"U" => "語法", "N" => "備考", "M" => "語義"} 
  CONTENT_ALPHABETS = {"M" => "語義", "E" => "語源", "U" => "語法", "N" => "備考", "P" => "成句", "S" => "例文"}

  module_function

  def search(search, mode = 0, type = 0, version = 0)
    whole_data = ShaleiaUtilities.fetch_whole_data(version)
    names = ShaleiaUtilities.fetch_names(version)
    equivalents = ShaleiaUtilities.fetch_equivalents(version)
    changes = ShaleiaUtilities.fetch_changes(version)
    hit_names, suggested_names = [], []
    if mode == 0 || mode == 3
      names.each do |name|
        modified_name = name.gsub(/\~/, "")
        if type == 2
          length = search.split(//).length
          (0...length).each do |i|
            sub_search = search.split(//)
            sub_search[i] = "."
            sub_search = sub_search.join
            if modified_name =~ /^#{sub_search}$/
              hit_names << name
            end
          end
        elsif (type == 0 && modified_name.start_with?(search)) || (type == 1 && modified_name =~ /#{search}/)
          hit_names << name
        end
        if type == 0 && version == 0
          TENSES.each do |tense_type, tense|
            ASPECTS.each do |aspect_type, aspect|
              NEGATION_PREFIXES.each do |nagation_type, nagation|
                if nagation + modified_name + tense + aspect == search
                  if whole_data[name] =~ /^\+.*〈.*動.*〉/
                    suggested_names << ["動詞型不定詞の活用 (#{tense_type}, #{aspect_type}, #{nagation_type})", name]
                  end
                elsif modified_name + tense + aspect == search
                  if whole_data[name] =~ /^\+.*〈.*動.*〉/
                    suggested_names << ["動詞型不定詞の活用 (#{tense_type}, #{aspect_type})", name]
                  end
                elsif nagation + modified_name == search
                  if whole_data[name] =~ /^\+.*〈.*名.*〉/
                    suggested_names << ["名詞型不定詞の活用 (#{nagation_type})", name]
                  end
                end
              end
            end
          end
          VERB_PREFIXES.each do |prefix_type, prefix|
            NEGATION_PREFIXES.each do |nagation_type, nagation|
              if prefix + nagation + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*動.*〉/
                  suggested_names << ["動詞型不定詞の活用 (#{prefix_type}, #{nagation_type})", name]
                end
              elsif prefix + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*動.*〉/
                  suggested_names << ["動詞型不定詞の活用 (#{prefix_type})", name]
                end
              end
            end
          end
          ADVERB_PREFIXES.each do |prefix_type, prefix|
            NEGATION_PREFIXES.each do |nagation_type, nagation|
              if prefix + nagation + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*副.*〉/
                  suggested_names << ["副詞型不定詞の活用 (#{prefix_type}, #{nagation_type})", name]
                end              
              elsif prefix + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*副.*〉/
                  suggested_names << ["副詞型不定詞の活用 (#{prefix_type})", name]
                end
              end
            end
          end
          PARTICLE_PREFIXES.each do |prefix_type, prefix|
            if prefix + modified_name == search
              if whole_data[name] =~ /^\+.*〈.*助.*〉/
                suggested_names << ["助接詞の活用 (#{prefix_type.gsub(/\d/, "")})", name]
              end
            end            
          end
          changes.each do |change_name, change_whole_data|
            if change_name == search
              change_whole_data.each do |change_data|
                suggested_names << ["単語の変更", change_data[0]]
              end
            end
          end
        end
      end
    end
    if mode == 1 || mode == 3
      equivalents.each do |name, names|
        if (type == 0 && name.start_with?(search)) || (type == 1 && name =~ /#{search}/)
          hit_names.concat(names)
        end
      end
    end
    if mode == 2
      if type == 1
        names.each do |name|
          data = whole_data[name]
          if data =~ /#{search}/
            hit_names << name
          end
        end
      end
    end
    hit_names.uniq!
    suggested_names.uniq!
    hit_names = hit_names.sort_by{|s| ShaleiaStringUtilities.convert_dictionary(s, version)}
    return [hit_names, suggested_names]
  end

  def parse(name, data, version = 0, struct = false)
    word = {}
    word["name"] = name
    word["pronunciation"] = (version == 0) ? ShaleiaStringUtilities.pronunciation(name) : nil
    word["date"] = 0
    word["sort"] = nil
    word["equivalents"] = []
    word["contents"] = []
    word["examples"] = []
    word["synonyms"] = []
    data.each_line do |line|
      if match = line.match(/^\+\s*(\d+)\s*〈(.+)〉/)
        word["date"] = match[1].to_i
        word["sort"] = match[2]
      end
      if match = line.match(/^\=\s*〈(.+?)〉\s*(.+)/)
        equivalent = {}
        equivalent["category"] = match[1]
        equivalent["names"] = match[2].chomp.split(/\s*,\s*/)
        equivalent = OpenStruct.new(equivalent) if struct
        word["equivalents"] << equivalent
      end
      if match = line.match(/^([^SO])>\s*(.+)/)
        content = {}
        content["type"] = CONTENT_ALPHABETS[match[1]]
        content["text"] = match[2].chomp
        content = OpenStruct.new(content) if struct
        word["contents"] << content
      end
      if match = line.match(/^S>\s*(.+)\s*→\s*(.+)/)
        example = {}
        example["type"] = CONTENT_ALPHABETS["S"]
        example["shaleian"] = match[1].chomp
        example["japanese"] = match[2].chomp
        example = OpenStruct.new(example) if struct
        word["examples"] << example
      end
      if match = line.match(/^\-\s*(?:〈(.+)〉)?\s*(.+)/)
        synonym = {}
        synonym["category"] = match[1]
        synonym["names"] = match[2].chomp.split(/\s*,\s*/)
        synonym = OpenStruct.new(synonym) if struct
        word["synonyms"] << synonym
      end
    end
    word = OpenStruct.new(word) if struct
    return word
  end

  def fetch_names(version = 0)
    names = Array.new
    if File.exist?("../../file/dictionary/meta/name/#{version + 1}.txt")
      File.open("../../file/dictionary/meta/name/#{version + 1}.txt") do |file|
        file.each_line do |line|
          if match = line.chomp.match(/^(.+)/)
            names << match[1]
          end
        end
      end
    end
    return names
  end

  def fetch_excluded_names
    names = File.read("../../file/dictionary/meta/other/exclusion.txt").split(/\s*\n\s*/)
    return names
  end

  def fetch_equivalents(version = 0)
    equivalents = Hash.new
    if File.exist?("../../file/dictionary/meta/equivalent/#{version + 1}.txt")
      File.open("../../file/dictionary/meta/equivalent/#{version + 1}.txt") do |file|
        file.each_line do |line|
          if match = line.chomp.match(/^(.+);\s*(.+)/)
            equivalents[match[1]] = match[2].split(/\s*,\s*/).reject{|s| s.match(/^\s*$/)}
          end
        end
      end
    end
    return equivalents
  end

  def fetch_changes(version = 0)
    changes = Hash.new{|h, s| h[s] = []}
    if File.exist?("../../file/dictionary/meta/change/#{version + 1}.txt")
      File.open("../../file/dictionary/meta/change/#{version + 1}.txt") do |file|
        file.each_line do |line|
          if match = line.chomp.match(/^(.+);\s*(.+),\s*(.+)/)
            changes[match[1]] << [match[2], match[3]]
          end
        end
      end
    end
    return changes
  end

  def fetch_logs
    logs = Array.new
    if File.exist?("../../file/dictionary/log/1.txt")
      File.open("../../file/dictionary/log/1.txt") do |file|
        file.each_line do |line|
          logs << line.chomp
        end
      end
    end
    return logs
  end

  def fetch_histories(version = 0)
    histories = Hash.new{|h, s| h[s] = 0}
    if File.exist?("../../file/dictionary/meta/history/#{version + 1}.txt")
      File.open("../../file/dictionary/meta/history/#{version + 1}.txt") do |file|
        file.each_line do |line|
          if match = line.chomp.match(/^(\d+);\s*(\d+)/)
            histories[match[1].to_i] = match[2].to_i
          end
        end
      end
    end
    return histories
  end

  def fetch_whole_data(version = 0)
    whole_data = Hash.new{|h, s| h[s] = ""}
    current_name = nil
    if File.exist?("../../file/dictionary/data/shaleia/#{version + 1}.xdc")
      File.open("../../file/dictionary/data/shaleia/#{version + 1}.xdc") do |file|
        file.each_line do |line|
          if match = line.chomp.match(/^\*\s*(.+)\s*$/)
            current_name = match[1]
          else
            whole_data[current_name] << line if current_name
          end
        end
      end
    end
    return whole_data
  end

  def fetch_whole_data_without_meta(version = 0)
    whole_data = ShaleiaUtilities.fetch_whole_data(version)
    whole_data.reject!{|s, t| s.start_with?("META") || s.start_with?("$")}
    return whole_data
  end

  def save_whole_data(whole_data, version = 0)
    output = ""
    whole_data = whole_data.sort
    whole_data.each do |name, content|
      output << "* #{name}\n#{content}\n"
    end
    output.gsub!(/\r\n/, "\n")
    output.gsub!(/\n\s*\n\s*\n/, "\n\n")
    return whole_data.size
  end

  def save_log(search, mode = 0, type = 0, version = 0)
    log = Time.now.strftime("%Y/%m/%d %H:%M:%S") + " (m=#{mode}, t=#{type}, v=#{version}): #{search}"
  end

  def delete_logs
    if File.exist?("../../file/dictionary/log/1.txt")
      File.delete("../../file/dictionary/log/1.txt")
    end
  end

  def save_history(version = 0)
    size = ShaleiaUtilities.fetch_whole_data_without_meta(version).size
    hairia = ShaleiaTime.now_hairia
    File.open("../../file/dictionary/meta/history/#{version + 1}.txt", "a") do |file|
      file.puts(hairia.to_s + "; " + size.to_s)
    end
    return size
  end

  def update(version = 0)
    whole_data = ShaleiaUtilities.fetch_whole_data(version)
    whole_names = Array.new
    whole_equivalents = Hash.new{|h, s| h[s] = []}
    whole_changes = Hash.new{|h, s| h[s] = []}
    whole_data.each do |name, content|
      if !name.match(/^(\$|META)/)
        equivalents = []
        content.each_line do |line|
          if match = line.match(/^\=\s*(.+)/)
            match = match[1]
            match.strip!
            match.gsub!(":", "")
            match.gsub!(/\(.+\)/u, "")
            match.gsub!(/〈.+〉/u, "")
            match.split(",").each do |equivalent|
              equivalent.strip!
              equivalent.gsub!(/\(.+?\)/, "")
              equivalent.gsub!("=", "")
              equivalent.gsub!("～", "")
              equivalent.gsub!("{", "")
              equivalent.gsub!("}", "")
              equivalent.gsub!("[", "")
              equivalent.gsub!("]", "")
              equivalents << equivalent
            end
          end
        end
        whole_names << name
        equivalents.each do |equivalent|
          whole_equivalents[equivalent] << name
        end
      elsif name == "META-CHANGE"
        content.each_line do |line|
          if match = line.match(/^\-\s*(\d+)\s*:\s*\{(.+)\}\s*→\s*\{(.+)\}/)
            whole_changes[match[2]] << [match[3], match[1]]
          end
        end
      end
    end
    name_text, equivalent_text, change_text = "", "", ""
    whole_names.each do |name|
      unless name == ""
        name_text << name + "\n"
      end
    end
    whole_equivalents.each do |equivalent, names|
      equivalent_text << equivalent + "; "
      names.each do |name|
        unless name == ""
          equivalent_text << name + ", "
        end
      end
      equivalent_text << "\n"
    end
    whole_changes.each do |name, changes|
      changes.each do |change|
        change_text << name + "; " + change[0] + ", " + change[1] + "\n"
      end
    end
    File.open("../../file/dictionary/meta/name/#{version + 1}.txt", "w") do |file|
      file.puts(name_text)
    end
    File.open("../../file/dictionary/meta/equivalent/#{version + 1}.txt", "w") do |file|
      file.puts(equivalent_text)
    end
    File.open("../../file/dictionary/meta/change/#{version + 1}.txt", "w") do |file|
      file.puts(change_text)
    end
    return whole_names.size
  end

  def upload(file, version = 0)
    File.open("../../file/dictionary/data/shaleia/#{version + 1}.xdc", "w") do |next_file|
      next_file.write(file.read)
    end
  end

end


module ShaleiaTime

  module_function

  def old_time(year, month, day, hour, minute, second)
    time = DateTime.new(year, month, day, hour, minute, second)
    base_time = DateTime.new(2012, 1, 23, 0, 0, 0)
    difference = ((time - base_time) * 120000 + 1500 * 36000000).to_i
    new_year = difference / 36000000 + 1
    new_month = difference % 36000000 / 3000000 + 1
    new_day = difference % 36000000 % 3000000 / 120000 + 1
    new_hour = difference % 36000000 % 3000000 % 120000 / 10000
    new_minute = difference % 36000000 % 3000000 % 120000 % 10000 / 100
    new_second = difference % 36000000 % 3000000 % 120000 % 10000 % 100
    return [new_year, new_month, new_day, new_hour, new_minute, new_second]
  end

  def new_time(year, month, day, hour, minute, second)
    time = DateTime.new(year, month, day, hour, minute, second.to_i) - 186651
    base_time = DateTime.new(time.year, 1, 1, time.hour, time.min, time.sec)
    modified_time = DateTime.new(time.year, time.month, time.day, 0, 0, 0)
    sub_second = second - second.to_i
    day_difference = (time - base_time).to_i
    time_difference = (time - modified_time).to_f * 86400 * 100000 / 86400 + sub_second
    new_year = time.year
    new_month = day_difference / 33 + 1
    new_day = day_difference % 33 + 1
    new_hour = time_difference / 10000
    new_minute = time_difference % 10000 / 100
    new_second = time_difference % 10000 % 100
    return [new_year, new_month, new_day, new_hour, new_minute, new_second]
  end

  def hairia(year, month, day)
    difference = DateTime.new(year, month, day, 0, 0, 0) - DateTime.new(2012, 1, 23, 0, 0, 0)
    hairia = (difference + 1).to_i
    return hairia
  end

  def now_hairia
    time = Time.now - 6 * 60 * 60
    hairia = ShaleiaTime.hairia(time.year, time.month, time.day)
    return hairia
  end

end


module ShaleiaStringUtilities

  ALPHABET_ORDERS = {
    0 => "sztdkgfvpbcqxjrlmnhyaâáàeêéèiîíìoôòuûù",
    1 => "skptfcxrlzgbdvqjnmyieaou",
    2 => "sztdkgfvpbxjrlmnhy'aeiou",
    3 => "sztdkgfvpbxjcqrlmnyaeiou",
    4 => "sztdkgfvpbxjrlmnhy'aeiou"
  }

  module_function

  def convert_punctuation(string)
    string = string.clone
    string.gsub!("、", "、 ")
    string.gsub!("。", "。 ")
    string.gsub!("「", " 「")
    string.gsub!("」", "」 ")
    string.gsub!("」 、", "」、")
    string.gsub!("」 。", "」。")
    string.gsub!("『", " 『")
    string.gsub!("』", "』 ")
    string.gsub!("』 、", "』、")
    string.gsub!("』 。", "』。")
    string.gsub!("〈", " 〈")
    string.gsub!("〉", "〉 ")
    string.gsub!("〉 、", "〉、")
    string.gsub!("〉 。", "〉。")
    string.gsub!("…", "<span class=\"japanese\">…</span>")
    string.gsub!("  ", " ")
    string.gsub!(/^\s*/, "")
    return string
  end

  def convert_dictionary(string, version = 0)
    string = string.clone.split(//)
    data = ALPHABET_ORDERS[version]
    string.map!{|s| (data.include?(s)) ? data.index(s) + 1 : -1}
    if string[0] == -1
      string.delete_at(0)
      string << -2
    end 
    return string
  end

  def pronunciation(name, level = 2)
    name = ShaleiaStringUtilities.divide_syllables(name)
    name = "kiɴ" if name == "<k><i><n>"
    name = "aɪ" if name == "<á>"
    name = "eɪ" if name == "<é>"
    name = "aʊ" if name == "<à>"
    name = "laɪ" if name == "<l><á>"
    name = "leɪ" if name == "<l><é>"
    name = "daʊ" if name == "<d><à>"
    name = "l" if name == "<l>"
    name = "ɴ" if name == "<n>"
    name.gsub!(/<(s|z|t|d|k|g|f|v|p|b|c|q|x|j|r|l|m|n|h|y)>.<\1>/){".<#{$1}>"}
    name.gsub!("<s>", "s")
    name.gsub!("<z>", "z")
    name.gsub!("<t>", "t")
    name.gsub!("<d>", "d")
    name.gsub!("<k>", "k")
    name.gsub!("<g>", "ɡ")
    name.gsub!("<f>", "f")
    name.gsub!("<v>", "v")
    name.gsub!("<p>", "p")
    name.gsub!("<b>", "b")
    name.gsub!("<c>", "θ")
    name.gsub!("<q>", "ð")
    name.gsub!("<x>", "ʃ")
    name.gsub!("<j>", "ʒ")
    name.gsub!("<r>", "ɹ")
    name.gsub!(/<l><(a|e|i|o|u|â|ê|î|ô|û|á|é|í|à|è|ì|ò|ù)>/){"l<#{$1}>"}
    name.gsub!("<l>", "ɾ")
    name.gsub!("<m>", "m")
    name.gsub!("<n>", "n")
    name.gsub!(/<h>(\.|$)/){["ə#{$1}", "ə#{$1}", $1][level]}
    name.gsub!(/<h><(a|e|i|o|u|â|ê|î|ô|û|á|é|í|à|è|ì|ò|ù)>/){"h<#{$1}>"}
    name.gsub!("<h>"){["ə", "", ""][level]}
    name.gsub!("<y>", "j")
    name.gsub!("<a>", "a")
    name.gsub!("<e>", "e")
    name.gsub!("<i>", "i")
    name.gsub!("<o>", "ɔ")
    name.gsub!("<u>", "u")
    name.gsub!("<â>"){["aː", "a", "a"][level]}
    name.gsub!("<ê>"){["eː", "e", "e"][level]}
    name.gsub!("<î>"){["iː", "i", "i"][level]}
    name.gsub!("<ô>"){["ɔː", "ɔ", "ɔ"][level]}
    name.gsub!("<û>"){["uː", "u", "u"][level]}
    name.gsub!("<á>"){["aɪ", "a", "a"][level]}
    name.gsub!("<é>"){["eɪ", "e", "e"][level]}
    name.gsub!("<í>"){["iə", "i", "i"][level]}
    name.gsub!("<à>"){["aʊ", "ɶ", "a"][level]}
    name.gsub!("<è>"){["eʊ", "ø", "e"][level]}
    name.gsub!("<ì>"){["iʊ", "y", "i"][level]}
    name.gsub!("<ò>"){["ɔɐ", "ʌ", "ɔ"][level]}
    name.gsub!("<ù>"){["uɐ", "ɯ", "u"][level]}
    name.gsub!(/<.>/, "")
    name.gsub!(".", "")
    return name
  end

  def divide_syllables(name)
    name = name.dup
    name.gsub!("'", "")
    name.gsub!("-", "")
    name = name.split(//).reverse.map{|s| "<#{s}>"}.join
    name.gsub!(/((<[sztdkgfvpbcqxjrlmnhy]>)?<[aeiouâêîôûáéíàèìòù]>(<[sztdkgfvpbcqxjrlmnhy]>)?)/){$1 + "."}
    name = name.scan(/(<.>|\.)/).reverse.join
    name[0] = "" if name[0..0] == "."
    return name
  end

end