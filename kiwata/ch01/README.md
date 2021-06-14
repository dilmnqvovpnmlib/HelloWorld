# 概要

- ハロー“Hello, World” OSと標準ライブラリのシゴトとしくみの 1 章を読んで、調査・検証したり、実装して得た知見をまとめていく。

## Docker 内で touch したファイルをホストで編集すると、権限の関係で編集できない (sudo ならできる) 問題が生じた

## 解決方法 (プロセス)

- 基本的には以下の記事に沿えば問題は解決する。

### 参考

- [dockerでvolumeをマウントしたときのファイルのowner問題](https://qiita.com/yohm/items/047b2e68d008ebb0f001)

## Docker image が Centos 6 である Docker のコンテナ内でパッケージの更新ができない

### 解決方法 (プロセス)

- Centos がサポートするバージョンのせいでパッケージを更新できませんでした。したがって、以下の記事を参考にパッケージのバージョンを見に行くパスを変更すればひとまずは正常に動作した。

### 参考

- [2020-11-30 でサポート終了した CentOS 6 にて、YumRepo Error: All mirror URLs are not using ftp, http[s] or file が発生する件（解決済み](https://qiita.com/imunew/items/3810a41960f40db85c94)

## ソースコードをコンパイルと解析コマンド

- プログラムをコンパイルする。`-g` オプションは、デバッガにようるデバッグを可能にするオプションである。また、`-O0` オプションは最適化を行わないようにするオプションである。

```bash
gcc -o hello hello.c -Wall -g -O0 -static
```

- 以下のコマンドで実行ファイルを逆アセンブルできる。アセンブリはインテル表示が良いので、`-M intel` オプションを付加した。

```bash
o -d -M intel hello
```

- 以下のコマンドで実行ファイルを解析することができる。

```bash
readelf -a hello
```
