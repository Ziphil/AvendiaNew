<div align="center">
<h1>『Avendia』生成スクリプト</h1>
</div>

![](https://img.shields.io/github/commit-activity/y/Ziphil/AvendiaNew?label=commits)
![](https://img.shields.io/github/search/Ziphil/AvendiaNew/extension:zml?label=pages)


## 概要
シャレイア語公式サイト『[Avendia](http://ziphil.com/)』を生成するためのスクリプトとその原稿ファイルです。

## 下準備

### Ruby の準備
生成スクリプトは [Ruby](https://www.ruby-lang.org/ja/) で書かれているため、まず最新の Ruby をインストールしてください。
バージョン 2.5 以上であれば動くはずです。
また、`ruby` や `gem` が呼び出せるように適切にパスを設定しておいてください。

### 依存 gem のインストール
依存している gem を管理するために [Bundler](https://bundler.io/) を用いています。
以下のコマンドを実行し、Bundler をインストールしてください。
```
gem install bundler
```

さらに、依存している gem をインストールするため、ディレクトリトップで以下のコマンドを実行してください。
```
bundle install
```

### npm モジュールとしての準備
TypeScript をコンパイルするために、npm を通じて必要なモジュールをインストールする必要があります。
まず、[Node.js](https://nodejs.org/ja/) をインストールし、`npm` が呼び出せるように適切にパスを設定しておいてください。
この状態で、ディレクトリトップで以下のコマンドを実行してください。
```
npm install
```

なお、この生成スクリプトは、TypeScript ファイルに対して以下のようなコマンドを実行し、標準出力を変換後のパスに保存しようとします。
```
browserify (変換前の絶対パス) -p [tsify -t ES6 --strict]
```

### 各種設定
変換したファイルの出力先やリモートサーバーのログイン情報などを設定しておく必要があります。
以下の様式の JSON ファイルを `config/config.json` として保存してください。
```jsonc
{
  "server": {
    "host": "********",  // サーバーのホスト名
    "user": "********",  // サーバーのユーザー名
    "password": "********"  // サーバーのパスワード
  },
  "local_domain": {  // ローカルサーバーのドメイン名
    "ja": "http://lbs.localhost",
    "en": "http://en.lbs.localhost"
  },
  "remote_domain": {  // リモートサーバーのドメイン名
    "ja": "http://ziphil.com",
    "en": "http://en.ziphil.com"
  },
  "document_dir": {  // 原稿ファイルが置かれるディレクトリの相対パス
    "ja": "document/ja",
    "en": "document/en"
  },
  "output_dir": {  // 変換ファイルの出力先となるディレクトリの絶対パス
    "ja": "C:/Apache24/htdocs/lbs",
    "en": "C:/Apache24/htdocs/lbs-en"
  },
  "remote_dir": {  // 変換ファイルのアップロード先となるディレクトリの絶対パス
    "ja": "",
    "en": "en.ziphil.com"
  },
  "log_path": {  // ログファイルの出力先の相対パス
    "ja": "log/ja.txt",
    "en": "log/en.txt",
    "error": "log/error.txt"
  },
  "program_path": {  // CGI のプログラムのパス
    "ruby": "/usr/bin/ruby"
  },
  "macro_dir": "macro",  // ZenML マクロの定義ファイルが置かれるディレクトリの相対パス
  "template_dir": "template"  // HTML への変換規則ファイルが置かれるディレクトリの相対パス
}
```

## 生成
以下のコマンドを実行すると、サイトの全てのページを出力ディレクトリに生成します。
```
bundle exec ruby converter/main.rb
```
オプション `-u` を付けると、生成と同時にファイルがサーバーにアップロードされます。
```
bundle exec ruby converter/main.rb -u
```
オプション `-s` を付けると、内容を変更したファイルのみが自動で変換されるようになります。
変換スクリプトがバックグラウンドで走り、コマンドを毎回実行しなくても、自動で変更を検知して生成を行います。
コンソールで Enter キーを押すと、変更の検知を終了します。

以下のようにファイル名を指定すると、全てのファイルもしくは変更したファイルではなく、指定されたファイルのみを生成します。
ファイルのパスは空白区切りで複数指定することができます。
```
bundle exec ruby converter/main.rb (ファイル名の絶対パス)
```
この場合も、オプション `-u` を付けることで、生成と同時にファイルをサーバーにアップロードできます。
```
bundle exec ruby converter/main.rb -u (ファイル名の絶対パス)
```

以下のコマンドによって、特定のファイルを更新したことをスクリプトに通知し、そのことを更新履歴として記録できます。
記録された更新履歴は、ページ原稿中に特定のタグを入れることで表示させることができます。
ただし、このコマンドは更新履歴データを更新するだけなので、実際のページに表示される履歴を更新したい場合は、そのページを別途再生成する必要があります。
```
bundle exec ruby converter/main.rb -l (ファイル名の絶対パス)
```
更新履歴は最大 1000 件まで保存されます。

変換中のエラーログは、設定されたファイルに書き込まれます。
変換中にエラーが発生したファイルは、コンソールに出力されるログにおいて黄背景で表示されます。

## 注意点

### 欠損ファイルについて
現在オンライン上にアップロードされているファイルのうち、以下に該当するものはこのリポジトリに含まれていません。
したがって、『Avendia』を完全に再現するためには、これらのファイルは別途用意する必要があります。

- .htaccess ファイル
- `document/ja/file/` 以下にあるファイル

このうち、辞書データは[別リポジトリ](https://github.com/Ziphil/ShaleianDictionary)で管理しています。
GitHub の Webhook 機能の通知を受け取るための CGI スクリプトを `(サーバーアドレス)/program/interface/1.cgi` として用意してあるので、ペイロード URL にこのアドレスを指定しておくと、プッシュ時などに自動でサーバー上のデータを更新できます。

### サイトの公開について
サイトの管理者である Ziphil の許可を得ずに、このリポジトリに含まれるファイルおよびそれを変換したファイルを、オンラインで公開することを禁じます。
この README の内容は Ziphil の備忘録にすぎず、クローンサイトの公開を推奨するものではありません。

## その他
各種ページの原稿は [ZenML](https://github.com/Ziphil/Zenithal) で書かれていて、このスクリプトによって HTML に変換しています。
ZenML で記述するタグについては、[こちら](http://ziphil.com/other/other/10.html)を参照してください。