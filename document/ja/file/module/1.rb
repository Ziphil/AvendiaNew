# coding: utf-8


module ShaleiaUtilities;extend self

  TENSES = {"現在時制" => "a", "過去時制" => "e", "未来時制" => "i", "通時時制" => "o"}
  INTRANSITIVE_ASPECTS = {"開始相, 自動詞" => "f", "経過相, 自動詞" => "c", "完了相, 自動詞" => "k", "継続相, 自動詞" => "t", "終了相, 自動詞" => "p", "無相, 自動詞" => "s"}
  TRANSITIVE_ASPECTS = {"開始相, 他動詞" => "v",  "経過相, 他動詞" => "q", "完了相, 他動詞" => "g", "継続相, 他動詞" => "d", "終了相, 他動詞" => "b", "無相, 他動詞" => "z"}
  VERB_PREFIXES = {"形容詞" => "a", "副詞" => "o"}
  ADVERB_PREFIXES = {"副詞" => "e"}
  PARTICLE_PREFIXES = {"非動詞修飾" => "i"}
  NEGATION_PREFIXES = {"否定" => "du"}
  USED_CAPTION_ALPHABETS = {"U" => "語法", "N" => "備考", "M" => "語義"} 
  CATEGORIES = {"名" => "noun", "動" => "verb", "形" => "adjective", "副" => "adverb", "助" => "preposition", "接" => "conjunction", "間" => "interjection", "縮" => "contraction"}
  ASPECTS = INTRANSITIVE_ASPECTS.merge(TRANSITIVE_ASPECTS)

  def search(search, mode = 0, type = 0, version = 0)
    whole_data = ShaleiaUtilities.whole_data(version)
    names = ShaleiaUtilities.names(version)
    equivalents = ShaleiaUtilities.equivalents(version)
    changes = ShaleiaUtilities.changes(version)
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
        elsif (type == 0 && modified_name == search) || (type == 1 && modified_name =~ /#{search}/)
          hit_names << name
        end
        if type == 0 && version == 0
          TENSES.each do |tense_type, tense|
            ASPECTS.each do |aspect_type, aspect|
              NEGATION_PREFIXES.each do |nagation_type, nagation|
                if nagation + modified_name + tense + aspect == search
                  if whole_data[name] =~ /^\+.*〈.*動.*〉/
                    suggested_names << ["動詞型不定詞の活用 (#{tense_type}, #{aspect_type}, #{nagation_type}) <span class=\"japanese\">…</span> ", name]
                  end
                elsif modified_name + tense + aspect == search
                  if whole_data[name] =~ /^\+.*〈.*動.*〉/
                    suggested_names << ["動詞型不定詞の活用 (#{tense_type}, #{aspect_type}) <span class=\"japanese\">…</span> ", name]
                  end
                elsif nagation + modified_name == search
                  if whole_data[name] =~ /^\+.*〈.*名.*〉/
                    suggested_names << ["名詞型不定詞の活用 (#{nagation_type}) <span class=\"japanese\">…</span> ", name]
                  end
                end
              end
            end
          end
          VERB_PREFIXES.each do |prefix_type, prefix|
            NEGATION_PREFIXES.each do |nagation_type, nagation|
              if prefix + nagation + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*動.*〉/
                  suggested_names << ["動詞型不定詞の活用 (#{prefix_type}, #{nagation_type}) <span class=\"japanese\">…</span> ", name]
                end
              elsif prefix + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*動.*〉/
                  suggested_names << ["動詞型不定詞の活用 (#{prefix_type}) <span class=\"japanese\">…</span> ", name]
                end
              end
            end
          end
          ADVERB_PREFIXES.each do |prefix_type, prefix|
            NEGATION_PREFIXES.each do |nagation_type, nagation|
              if prefix + nagation + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*副.*〉/
                  suggested_names << ["副詞型不定詞の活用 (#{prefix_type}, #{nagation_type}) <span class=\"japanese\">…</span> ", name]
                end              
              elsif prefix + modified_name == search
                if whole_data[name] =~ /^\+.*〈.*副.*〉/
                  suggested_names << ["副詞型不定詞の活用 (#{prefix_type}) <span class=\"japanese\">…</span> ", name]
                end
              end
            end
          end
          PARTICLE_PREFIXES.each do |prefix_type, prefix|
            if prefix + modified_name == search
              if whole_data[name] =~ /^\+.*〈.*助.*〉/
                suggested_names << ["助接詞の活用 (#{prefix_type.gsub(/\d/, "")}) <span class=\"japanese\">…</span> ", name]
              end
            end            
          end
          changes.each do |change_name, change_whole_data|
            if change_name == search
              change_whole_data.each do |change_data|
                suggested_names << ["単語の変更 <span class=\"japanese\">…</span> <span class=\"sans\">#{search}</span> → ", change_data[0]]
              end
            end
          end
        end
      end
    end
    if mode == 1 || mode == 3
      equivalents.each do |name, names|
        if (type == 0 && name == search) || (type == 1 && name =~ /#{search}/)
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
    hit_names = hit_names.sort_by{|s| s.convert_dictionary(version)}
    return [hit_names, suggested_names]
  end

  def names(version = 0)
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

  def equivalents(version = 0)
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

  def changes(version = 0)
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

  def logs
    logs = []
    if File.exist?("../../file/dictionary/log/1.txt")
      File.open("../../file/dictionary/log/1.txt") do |file|
        file.each_line do |line|
          logs << line.chomp
        end
      end
    end
    return logs
  end

  def whole_data(version = 0)
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

  def update(version = 0)
    whole_data = ShaleiaUtilities.whole_data(version)
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


module RequestUtilities;extend self

  def requests
    requests = Array.new
    if File.exist?("../../file/dictionary/meta/request/1.txt")
      File.open("../../file/dictionary/meta/request/1.txt") do |file|
        file.each_line do |line|
          requests << line.chomp
        end
      end
    end
    return requests
  end

  def add(requests)
    File.open("../../file/dictionary/meta/request/1.txt", "a") do |file|
      requests.each do |request|
        file.puts(request)
      end
    end
  end

  def delete_at(index)
    requests = RequestUtilities.requests
    requests.delete_at(index)
    File.open("../../file/dictionary/meta/request/1.txt", "w") do |file|
      requests.each do |request|
        file.puts(request)
      end
    end
  end

end


module ShaleiaTime;extend self

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
    return (difference + 1).to_i
  end

end


class String

  ALPHABET_ORDERS = {
    0 => "sztdkgfvpbcqxjrlmnhyaâáàeêéèiîoôòuûù",
    1 => "skptfcxrlzgbdvqjnmyieaou",
    2 => "sztdkgfvpbxjrlmnhy'aeiou",
    3 => "sztdkgfvpbxjcqrlmnyaeiou",
    4 => "sztdkgfvpbxjrlmnhy'aeiou"
  }

  def convert_punctuation
    string = self.clone
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

  def convert_dictionary(version = 0)
    string = self.clone.split(//)
    data = ALPHABET_ORDERS[version]
    string.map!{|s| (data.include?(s)) ? data.index(s) + 1 : -1}
    if string[0] == -1
      string.delete_at(0)
      string << -2
    end 
    return string
  end

  def to_new_orthography
    string = self.clone
    string.gsub!("aa", "â")
    string.gsub!("ee", "ê")
    string.gsub!("ii", "î")
    string.gsub!("oo", "ô")
    string.gsub!("uu", "û")
    string.gsub!("ai", "á")
    string.gsub!("ei", "é")
    string.gsub!("ie", "í")
    string.gsub!("au", "à")
    string.gsub!("eu", "è")
    string.gsub!("iu", "ì")
    string.gsub!("oa", "ò")
    string.gsub!("ua", "ù")
    return string
  end

  def to_old_orthography
    string = self.clone
    string.gsub!("â", "aa")
    string.gsub!("ê", "ee")
    string.gsub!("î", "ii")
    string.gsub!("ô", "oo")
    string.gsub!("û", "uu")
    string.gsub!("á", "ai")
    string.gsub!("é", "ei")
    string.gsub!("í", "ie")
    string.gsub!("à", "au")
    string.gsub!("è", "eu")
    string.gsub!("ì", "iu")
    string.gsub!("ò", "oa")
    string.gsub!("ù", "ua")
    return string
  end

  def pronunciation(level = 2)
    string = self.clone
    string = string.devide
    string = "kiɴ" if string == "<k><i><n>"
    string = "aɪ" if string == "<á>"
    string = "eɪ" if string == "<é>"
    string = "aʊ" if string == "<à>"
    string = "laɪ" if string == "<l><á>"
    string = "leɪ" if string == "<l><é>"
    string = "daʊ" if string == "<d><à>"
    string = "l" if string == "<l>"
    string = "ɴ" if string == "<n>"
    string.gsub!(/<(s|z|t|d|k|g|f|v|p|b|c|q|x|j|r|l|m|n|h|y)>.<\1>/){".<#{$1}>"}
    string.gsub!("<s>", "s")
    string.gsub!("<z>", "z")
    string.gsub!("<t>", "t")
    string.gsub!("<d>", "d")
    string.gsub!("<k>", "k")
    string.gsub!("<g>", "ɡ")
    string.gsub!("<f>", "f")
    string.gsub!("<v>", "v")
    string.gsub!("<p>", "p")
    string.gsub!("<b>", "b")
    string.gsub!("<c>", "θ")
    string.gsub!("<q>", "ð")
    string.gsub!("<x>", "ʃ")
    string.gsub!("<j>", "ʒ")
    string.gsub!("<r>", "ɹ")
    string.gsub!(/<l><(a|e|i|o|u|â|ê|î|ô|û|á|é|í|à|è|ì|ò|ù)>/){"l<#{$1}>"}
    string.gsub!("<l>", "ɾ")
    string.gsub!("<m>", "m")
    string.gsub!("<n>", "n")
    string.gsub!(/<h>(\.|$)/){["ə#{$1}", "ə#{$1}", $1][level]}
    string.gsub!(/<h><(a|e|i|o|u|â|ê|î|ô|û|á|é|í|à|è|ì|ò|ù)>/){"h<#{$1}>"}
    string.gsub!("<h>"){["ə", "", ""][level]}
    string.gsub!("<y>", "j")
    string.gsub!("<a>", "a")
    string.gsub!("<e>", "e")
    string.gsub!("<i>", "i")
    string.gsub!("<o>", "ɔ")
    string.gsub!("<u>", "u")
    string.gsub!("<â>"){["aː", "a", "a"][level]}
    string.gsub!("<ê>"){["eː", "e", "e"][level]}
    string.gsub!("<î>"){["iː", "i", "i"][level]}
    string.gsub!("<ô>"){["ɔː", "ɔ", "ɔ"][level]}
    string.gsub!("<û>"){["uː", "u", "u"][level]}
    string.gsub!("<á>"){["aɪ", "a", "a"][level]}
    string.gsub!("<é>"){["eɪ", "e", "e"][level]}
    string.gsub!("<í>"){["iə", "i", "i"][level]}
    string.gsub!("<à>"){["aʊ", "ɶ", "a"][level]}
    string.gsub!("<è>"){["eʊ", "ø", "e"][level]}
    string.gsub!("<ì>"){["iʊ", "y", "i"][level]}
    string.gsub!("<ò>"){["ɔɐ", "ʌ", "ɔ"][level]}
    string.gsub!("<ù>"){["uɐ", "ɯ", "u"][level]}
    string.gsub!(/<.>/, "")
    string.gsub!(".", "")
    return string
  end

  def devide
    string = self.clone
    string.gsub!("'", "")
    string.gsub!("-", "")
    string = string.split(//).reverse.map{|s| "<#{s}>"}.join
    string.gsub!(/((<[sztdkgfvpbcqxjrlmnhy]>)?<[aeiouâêîôûáéíàèìòù]>(<[sztdkgfvpbcqxjrlmnhy]>)?)/){$1 + "."}
    string = string.scan(/(<.>|\.)/).reverse.join
    string[0] = "" if string[0..0] == "."
    return string
  end

  def url_escape
    string = self.clone
    string.gsub!("%", "%25")
    string.gsub!(" ", "%20")
    string.gsub!("+", "%2B")
    string.gsub!("&", "%26")
    string.gsub!("=", "%3D")
    string.gsub!("?", "%3F")
    return string
  end

  def html_escape
    string = self.clone
    string.gsub!("&", "&amp;")
    string.gsub!("<", "&lt;")
    string.gsub!(">", "&gt;")
    string.gsub!("\"", "&quot;")
    return string
  end

end