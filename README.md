<div align="center">
<h1>『Avendia』生成スクリプト</h1>
</div>


## 概要
シャレイア語公式サイト『[Avendia](http://ziphil.com/)』を生成するためのスクリプトとその原稿ファイルです。

## 下準備

### Ruby の準備
生成スクリプトは Ruby で書かれています。
バージョン 2.5 以上の Ruby が必要です。

さらに、この生成スクリプトは、[ZenML](https://github.com/Ziphil/Zenithal) のパーサーライブラリを利用しています。
RubyGems からインストールしてください。
```
gem install zenml
```

### SASS/SCSS 処理系の準備
適当な SASS/SCSS 処理系をインストールし、それを実行できるようにパスの設定などをしてください。
この生成スクリプトは、以下のようなコマンドを実行しようとします。
```
sass --style=compressed --cache-location='(サーバールート)/.sass-cache' '(変換前の絶対パス)':'(変換後の絶対パス)'
```

### TypeScript コンパイラの準備
TypeScript 処理系をインストールし、それを実行できるようにパスの設定などをしてください。
この生成スクリプトは、以下のようなコマンドを実行しようとします。
```
tsc --strictNullChecks --noImplicitAny -t ES6 (変換前の絶対パス) --outFile (変換後の絶対パス)
```

TypeScript 処理系の準備は、例えば [Node.js](https://nodejs.org/ja/) を経由して以下のように可能です。
まず、Node.js をインストールし、`npm` が呼び出せるように適切にパスを設定しておいてください。
この状態で、以下のコマンドを実行します。
```
npm install -g typescript
npm install -g @types/jquery
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
ruby converter/main.rb
```
生成と同時にファイルをサーバーにアップロードしたいときは、オプション `-u` を付けてください。
```
ruby converter/main.rb -u
```

全てのページではなく特定のページのみを生成したい場合は、以下のコマンドを実行してください。
ファイルのパスは空白区切りで複数指定することができます。
```
ruby converter/main.rb (ファイル名の絶対パス)
```
この場合も、生成と同時にファイルをサーバーにアップロードしたいときは、オプション `-u` を付けてください。
```
ruby converter/main.rb -u (ファイル名の絶対パス)
```

以下のコマンドによって、特定のファイルを更新したことをスクリプトに通知し、そのことを更新履歴として記録できます。
記録された更新履歴は、ページ原稿中に特定のタグを入れることで表示させることができます。
ただし、このコマンドは更新履歴データを更新するだけなので、実際のページに表示される履歴を更新したい場合は、そのページを別途再生成する必要があります。
```
ruby converter/main.rb -l (ファイル名の絶対パス)
```
更新履歴は、`log/ja.txt` もしくは `log/en.txt` として最大 1000 件まで保存されます。

## 注意点

### TypeScript のパスについて
内部で jQuery を使用している TypeScript コードでは、jQuery の型定義ファイルを絶対パスで指定してあります。
そのため、これを正しくコンパイルするには、絶対パスの部分を各自の環境に合わせて書き換える必要があります。

明らかに良くない仕様なので、いずれどうにかする予定です。

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