# coding: utf-8


module WordConverter

  DEFAULT_LEFT_NAMES = ["s'", "al'", "ac'", "di'"]

  module_function

  def convert(string, url, link = true, version = 0, left_names = nil, option_string = "")
    left_names ||= DEFAULT_LEFT_NAMES
    if link
      string = "%" + string.gsub(/\s+/, "% %").gsub("-", "%-%") + "%"
      string.gsub!(/%([\"\[«…]*)(.*?)([!\?\.,\"\]»…]*)%/) do
        left, matched_name, right = $1, $2, $3
        modified_name = matched_name.gsub(/<\/?\w+>/, "")
        if version == 0 && matched_name.match(/(.+)'(.+)/)
          abbreviation_left, abbreviation_right = $1, $2
          modified_left = abbreviation_left.gsub(/<\/?\w+>/, "")
          modified_right = abbreviation_right.gsub(/<\/?\w+>/, "")
          if left_names.include?("#{modified_left}'")
            html = left
            if abbreviation_left =~ /^[0-9:]$/
              html << abbreviation_left + "'"
            else
              html << "<a href=\"#{url}?search=#{modified_left}'&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{abbreviation_left}'</a>"
            end
            if abbreviation_right =~ /^[0-9:]$/
              html << abbreviation_right
            else
              html << "<a href=\"#{url}?search=#{modified_right}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{abbreviation_right}</a>"
            end
            html << right
            next html
          else
            html = left
            if abbreviation_left =~ /^[0-9:]$/
              html << abbreviation_left
            else
              html << "<a href=\"#{url}?search=#{modified_left}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{abbreviation_left}</a>"
            end
            if abbreviation_right =~ /^[0-9:]$/
              html << "'" + abbreviation_right
            else
              html << "<a href=\"#{url}?search='#{modified_right}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">'#{abbreviation_right}</a>"
            end
            html << right
            next html
          end
        else
          html = left
          if matched_name =~ /^[0-9:]$|^ʻ|^—$/
            html << matched_name
          else
            html << "<a href=\"#{url}?search=#{modified_name}&amp;mode=search&amp;type=0&amp;agree=0#{option_string}\" rel=\"nofollow\">#{matched_name}</a>"
          end
          html << right
          next html
        end
      end
      return "<span class=\"sans\">#{string}</span>"
    else
      return "<span class=\"sans\">#{string}</span>"
    end
  end

end