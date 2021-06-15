# 概要

- ハロー“Hello, World” OSと標準ライブラリのシゴトとしくみの 2 章を読んで、調査・検証したり、実装して得た知見をまとめていく。

## gdb peda をインストールする

### セットアップ方法

- 基本的には、参考の [1] を参考にセットアップを行う。ただし、以下の操作だけでは `source ~/peda/peda.py` でエラーが生じてしまう。

```bash
mkdir ~/peda
git clone https://github.com/longld/peda.git 
mv peda ~/peda
echo "source ~/peda/peda.py" >> ~/.gdbinit
```

### エラーの解決方法

- まず、`source ~/peda/peda.py` を実行すると、以下のエラーが生じた。

```bash
Traceback (most recent call last):
File "~/peda/peda.py", line 40, in
File "/root/peda/lib/shellcode.py", line 35
return {k: six.b(v) for k, v in dict_.items()}
^
SyntaxError: invalid syntax
```

- `SyntaxError` なので、単純に dict の文法間違いである。適当にエラー文でググると、参考になる [2] が出てきた。そこに貼られている [3] の issue に飛ぶ。その issue は close されていて、差分の [4] のコミットを見ると、以下の正常な挙動をしそうなパッチが書かれていた。これを `/peda/lib/shellcode.py` に適用させる。そうすると次のエラーに移った。

```python
def _make_values_bytes(dict_):
    """Make shellcode in dictionaries bytes"""
    return dict((k, six.b(v)) for k, v in dict_.items())


shellcode_x86_linux = _make_values_bytes({
```

- 次に、`source ~/peda/peda.py` を実行すると `if sys.version_info.major == 3:` 周りでエラーが生じた。今回の Docker の CentOS のバージョンは書籍と合わせた 6 を使っている。その環境下においては、デフォルトの Python のバージョンが 2 である。そこで、このエラーが生じている `peda.py` の [45 行目](https://github.com/longld/peda/blob/84d38bda505941ba823db7f6c1bcca1e485a2d43/peda.py#L45) の Python のバージョンで条件分岐している箇所をコメントアウトして、Python 2 系では動くようなライブラリにする。こうして、`source ~/peda/peda.py` を実行すると、エラーが出ることなく GDB を動かすことができた。

### 参考

1. [peda](https://github.com/longld/peda)
2. [invalid syntax in peda/lib/shellcode.py](https://github.com/longld/peda/issues/99)
3. [Changed dict comprehension for 2.6.6 support](https://github.com/longld/peda/pull/59)
4. [Files changed](https://github.com/longld/peda/pull/59/files)

## バイナリ hello を GDB のデバッガを使って動的解析を行う

```
break main
break vfprintf
break *0x080597f5
break _IO_new_file_xsputn
break *0x80674b1
break _IO_new_do_write
break *0x8068258
break _IO_new_file_write
break *0x806772c
break write
break *0x8053f5c

run
layout asm
```

`_IO_new_do_write` に breakpoint を張って、2 回 continue をすると、メッセージが表示される。
従って、continue を 1 回実行した後に nexti で処理を進めていき、メッセージが表示される call 命令の箇所を調査する。
次に、`break *0x8068258` でブレークポイントを張って `c` を実行する。そうすると、メッセージが表示されてしまう。したがって、`si` で処理を進めていく。

`write` の呼び出しが見つかるので、`write` にブレークポイントを張って、`ni` コマンドで処理を進めていく。
関数の中にステップインしたい時に `si` を行うs。例えば、`call hoge` にカーソルが当たっている時に、`ni` を実行すると、処理が終わってメッセージが表示されてしまう可能性がある。しかし、`si` を行うと、その `call` されて呼出される関数の中に入って処理を追うことができる。

```
break *0x8053f5c
run
layout asm
```

## CentOS で hexedit をインストールするのが面倒臭いので、ホストでバイナリを書き換える

- 1 の記事を参考にパッケージを更新しても上手くいかなかった。そもそも本と合わせて CentOS のバージョンを古いものにしているので、その不整合差が悪さをしている可能性がある。そこで、バイナリを書き換えるのはホスト側にして、書き換えるアドレスを確認するのは、コンテナ内でするようにする。
- どうやら、2 の記事を参考にすると、古い CentOS のパッケージ管理は難しそうであるので、今回はそこは飛ばすような方法を選択した。

### 参考

1. [CentOS/パッケージアップデートがあるのにNo Packages marked for Updateが表示される ](https://linux.just4fun.biz/?CentOS/%E3%83%91%E3%83%83%E3%82%B1%E3%83%BC%E3%82%B8%E3%82%A2%E3%83%83%E3%83%97%E3%83%87%E3%83%BC%E3%83%88%E3%81%8C%E3%81%82%E3%82%8B%E3%81%AE%E3%81%ABNo+Packages+marked+for+Update%E3%81%8C%E8%A1%A8%E7%A4%BA%E3%81%95%E3%82%8C%E3%82%8B)
2. [yum updateが動いていない？][https://q.hatena.ne.jp/1314918492]

## バイナリエディタ hexedit で実行ファイル hello を書き換えてシステムコールが呼出されないようにする

- 書き換える命令のアドレスを GDB から見つける。
- 上で見つけたアドレスと objdump の結果から、書き換えるバイナリを見つける。
- 上で見つけた書き換えたいバイナリを hexedit を使って nop(0x90) で書き換える。
- バイナリを書き換えたファイルを実行すると、メッセージが表示されない。
