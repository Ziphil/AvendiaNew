<div align="center">
<h1>『Avendia』生成スクリプト</h1>
</div>


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

### サーバーのドキュメントルートの設定
適当な Web サーバーソフトウェア (Apache Server など) をインストールしてください。
その後、サーバーのドキュメントルートの絶対パスを、末尾に改行を含めずに `config/local.txt` として保存してください。
ここで指定したディレクトリが生成されたファイルの出力先となります。

### オンラインサーバーの設定
以下の情報を、順に改行で区切って `config/online.txt` として保存してください。

- サーバーのホスト名
- ログイン用のユーザー名
- ログイン用のパスワード

## 生成
サイトの全てのページを出力ディレクトリに生成するには、以下のコマンドを実行してください。
```
bundle exec ruby converter/main.rb
```
生成と同時にファイルをサーバーにアップロードしたいときは、オプション `-u` を付けてください。
```
bundle exec ruby converter/main.rb -u
```

内容を変更したページのみを自動で生成したいときは、オプション `-s` を付けてください。
生成スクリプトがバックグラウンドで走り、コマンドを毎回実行しなくても、自動で変更を検知して生成を行います。

全てのページもしくは変更したページではなく、ある特定のページのみを生成したい場合は、以下のコマンドを実行してください。
ファイルのパスは空白区切りで複数指定することができます。
```
bundle exec ruby converter/main.rb (ファイル名の絶対パス)
```
この場合も、生成と同時にファイルをサーバーにアップロードしたいときは、オプション `-u` を付けてください。
```
bundle exec ruby converter/main.rb -u (ファイル名の絶対パス)
```

以下のコマンドによって、特定のファイルを更新したことをスクリプトに通知し、そのことを更新履歴として記録できます。
記録された更新履歴は、ページ原稿中に特定のタグを入れることで表示させることができます。
ただし、このコマンドは更新履歴データを更新するだけなので、実際のページに表示される履歴を更新したい場合は、そのページを別途再生成する必要があります。
```
bundle exec ruby converter/main.rb -l (ファイル名の絶対パス)
```
更新履歴は、`log/ja.txt` もしくは `log/en.txt` として最大 1000 件まで保存されます。

変換中のエラーログは `log/error.txt` に保存されます。
変換中にエラーが発生したファイルは、コンソールに出力されるログにおいて黄背景で表示されます。

## 注意点

### 欠損ファイルについて
現在オンライン上にアップロードされているファイルのうち、以下に該当するものはこのリポジトリに含まれていません。
したがって、『Avendia』を完全に再現するためには、これらのファイルは別途用意する必要があります。

- .htaccess ファイル
- `document/ja/style/reset.css`
- `document/ja/file/script/cookie.js`
- `document/ja/file/script/jquery.js`
- `document/ja/file/script/xdomain.js`
- `document/ja/file/application/` 以下にある画像ファイル
- `document/ja/file/character/` 以下にある画像ファイル
- `document/ja/file/cource/` 以下にある PDF ファイル
- `document/ja/file/dictionary/` 以下にある辞書データ関連ファイル
- `document/ja/file/game/` 以下にある画像ファイル
- `document/ja/file/grammer/` 以下にある PDF ファイル
- `document/ja/file/mathematics/` 以下にある PDF ファイル
- `document/ja/file/mathematics_diary/` 以下にある PDF ファイル
- `document/ja/file/other/` 以下にある画像ファイル

このうち、辞書データは[別リポジトリ](https://github.com/Ziphil/ShaleianDictionary)で管理しています。
GitHub の Webhook 機能の通知を受け取るための CGI スクリプトを `(サーバーアドレス)/file/interface/1.cgi` として用意してあるので、ペイロード URL にこのアドレスを指定しておくと、プッシュ時などに自動でサーバー上のデータを更新できます。

### サイトの公開について
サイトの管理者である Ziphil の許可を得ずに、このリポジトリに含まれるファイルおよびそれを変換したファイルを、オンラインで公開することを禁じます。
この README の内容は Ziphil の備忘録にすぎず、クローンサイトの公開を推奨するものではありません。

## その他
各種ページの原稿は [ZenML](https://github.com/Ziphil/Zenithal) で書かれていて、このスクリプトによって HTML に変換しています。
ZenML で記述するタグについては、[こちら](http://ziphil.com/other/other/10.html)を参照してください。