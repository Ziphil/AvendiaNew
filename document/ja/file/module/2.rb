# coding: utf-8


module WordConverter;extend self

  DEFAULT_LEFT_NAMES = ["s'", "al'", "ac'", "di'"]

  def convert(match, url, link = true, version = 0, left_names = nil, option_string = "")
    left_names ||= DEFAULT_LEFT_NAMES
    if link
      match = "%" + match.gsub(/\s+/, "% %").gsub("-", "%-%") + "%"
      match.gsub!(/%([\"\[«…]*)(.*?)([!\?\.,\"\]»…]*)%/) do
        left, matched_name, right = $1, $2, $3
        modified_name = matched_name.gsub(/<\/?\w+>/, "")
        if version == 0 && matched_name.match(/(.+)'(.+)/)
          abbreviation_left, abbreviation_right = $1, $2
          modified_left = abbreviation_left.gsub(/<\/?\w+>/, "")
          modified_right = abbreviation_right.gsub(/<\/?\w+>/, "")
          if left_names.include?("#{modified_left}'")
            link = left
            if abbreviation_left =~ /^[0-9:]$/
              link << abbreviation_left + "'"
            else
              link << "<a href=\"#{url}?search=#{modified_left}'&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{abbreviation_left}'</a>"
            end
            if abbreviation_right =~ /^[0-9:]$/
              link << abbreviation_right
            else
              link << "<a href=\"#{url}?search=#{modified_right}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{abbreviation_right}</a>"
            end
            link << right
            next link
          else
            link = left
            if abbreviation_left =~ /^[0-9:]$/
              link << abbreviation_left
            else
              link << "<a href=\"#{url}?search=#{modified_left}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{abbreviation_left}</a>"
            end
            if abbreviation_right =~ /^[0-9:]$/
              link << "'" + abbreviation_right
            else
              link << "<a href=\"#{url}?search='#{modified_right}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">'#{abbreviation_right}</a>"
            end
            link << right
            next link
          end
        else
          link = left
          if matched_name =~ /^[0-9:]$|^ʻ|^—$/
            link << matched_name
          else
            link << "<a href=\"#{url}?search=#{modified_name}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{matched_name}</a>"
          end
          link << right
          next link
        end
      end
      return "<span class=\"sans\">#{match}</span>"
    else
      return "<span class=\"sans\">#{match}</span>"
    end
  end

end