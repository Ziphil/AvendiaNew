# coding: utf-8


class String

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