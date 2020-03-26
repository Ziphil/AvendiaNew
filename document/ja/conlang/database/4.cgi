#!/usr/bin/ruby
# coding: utf-8


require 'cgi'
require 'date'
require_relative '../../file/module/1'
require_relative '../../file/module/2'
require_relative '../../file/module/3'

Encoding.default_external = "UTF-8"
$stdout.sync = true


class DictionaryDownloader < CustomBase

  def prepare
    @mode = @cgi["mode"]
    @type = @cgi["type"]
  end

  def switch
    case @mode
    when "download"
      download
    else
      default
    end
  end

  def default
    html = ""
    html << "<h1>概要</h1>\n"
    html << "<p>\n"
    html << "辞書ソフトウェア 『Personal Dictionary Unicode』 および 『ZpDIC』 で使用できる辞書データがダウンロードできます。\n"
    html << "ZpDIC は<a href=\"../../application/download/2.html\">こちら</a>からダウンロードできます。"
    html << "</p>\n"
    html << "<h1>ダウンロード</h1>\n"
    html << "<h2>ZpDIC 版</h2>\n"
    html << "<p>\n"
    html << "全てのデータを含む完全版です。\n"
    html << "</p>\n"
    html << "<form>\n"
    html << "<input type=\"submit\" value=\"ダウンロード\"></input>　(#{ShaleiaUtilities.names.size} 語)\n"
    html << "<input type=\"hidden\" name=\"type\" value=\"zpdic\"></input>\n"
    html << "<input type=\"hidden\" name=\"mode\" value=\"download\"></input>\n"
    html << "</form>\n"
    html << "<h2>OTM-JSON 形式</h2>\n"
    html << "<p>\n"
    html << "シャレイア語辞典形式からの自動生成なので、 体裁などが見にくくなってしまっている可能性があります。\n" 
    html << "造語日などの一部のデータは含まれていません。\n"
    html << "</p>\n"
    html << "<p>\n"
    html << "生成と更新は手動なので、 常に最新のデータであるわけではありません。\n"
    html << "</p>\n"
    html << "<form>\n"
    html << "<input type=\"submit\" value=\"ダウンロード\"></input>\n"
    html << "<input type=\"hidden\" name=\"type\" value=\"otm\"></input>\n"
    html << "<input type=\"hidden\" name=\"mode\" value=\"download\"></input>\n"
    html << "</form>\n"
    html << "<h2>PDIC 版</h2>\n"
    html << "<p>\n"
    html << "このデータは Unicode 版用のものなので、 Unicode 版ではない PDIC では正常に読み込めません。\n"
    html << "また、 古いバージョンの PDIC を使っている場合、 データを読み込むときにエラーが出る場合があります。\n"
    html << "その場合は、 最新版の PDIC にアップロードするようお願いします。\n"
    html << "</p>\n"
    html << "<p>\n"
    html << "シャレイア語辞典形式からの自動生成なので、 体裁などが見にくくなってしまっている可能性があります。\n"
    html << "造語日などの一部のデータは含まれていません。"
    html << "</p>\n"
    html << "<p>\n"
    html << "生成と更新は手動なので、 常に最新のデータであるわけではありません。\n"
    html << "このデータは特に古いので、 多くの新しい単語が登録されていません。\n"
    html << "</p>\n"
    html << "<form>\n"
    html << "<input type=\"submit\" value=\"ダウンロード\"></input>\n"
    html << "<input type=\"hidden\" name=\"type\" value=\"pdic\"></input>\n"
    html << "<input type=\"hidden\" name=\"mode\" value=\"download\"></input>\n"
    html << "</form>\n"
    header = Source.header
    @cgi.out{Source.whole(header, html)}
  end

  def download
    case @type
    when "pdic"
      header = {"type" => "application/oct-stream", "Content-Disposition" => "download;filename=shaleia.dic"}
      file = File.new("../../file/dictionary/data/personal/1.dic")
    when "otm"
      header = {"type" => "application/oct-stream", "Content-Disposition" => "download;filename=shaleia.json"}
      file = File.new("../../file/dictionary/data/slime/1.json")
    when "zpdic"
      header = {"type" => "application/oct-stream", "Content-Disposition" => "download;filename=shaleia.xdc"}
      file = File.new("../../file/dictionary/data/shaleia/1.xdc")
    end
    @cgi.out(header){file.read}
  end

end


module Source

  module_function

  def header
    html = ""
    return html
  end

  def whole(header, main = "", footer = "")
    html = File.read("4.html")
    html.gsub!(/<special>.*?<\/special>|<special\/>/){header + main + footer}
    return html
  end

end


DictionaryDownloader.new(nil, CGI.new, Source).run