DCburn - ブート可能な NetBSD/dreamcast CD-R 作成キット


1. DCburn って何?

この "DCburn" イメージは、NetBSD/dreamcast 用のブート可能な CD-R を焼くための用意を、
簡単にできるようにしたものです。


2. DCburn イメージの内容

このイメージには、ブート可能な NetBSD/i386 ファイルシステムイメージが含まれており、
ブート可能な CD-R を焼くために必要な cdrtools パッケージ、NetBSD/dreamcast
カーネル、Makefile が含まれています。実際に CD-R を焼くために必要なファイルや道具の一部は、
インターネットから取得します。


3. 必要なもの

-  x86 ベースの PC で、NIC と CD-R ドライブを持ち、USB デバイスからのブートが可能なもの
  (そして、NetBSD/i386 が対応しているもの :-)
- DHCP によるインターネット接続


4. DCburn の使い方

1) 512MB (以上) の USB フラッシュメモリーに、
    このイメージを、gzip(1) と dd(1) を使って書き込みます
   (Windows 用の Rawrite32.exe ツールも使えます)。
    Rawrite32.exe ツールは以下のサイトにあります:
    http://www.NetBSD.org/~martin/rawrite32/
2) USB メモリーを x86 PC に挿し、そこから起動します (起動方法はマシン毎に異なります)
3) "login:" プロンプトで "root" でログインします。
4) インターネットに接続できていることを確認します ("ping www.netbsd.org" するなど)
   (なお、ブート中、"no interfaces have a carrier" メッセージは無視して構いません)
5) ブランク CD-R メディアをドライブに入れます
6) シェルプロンプトで "make" とだけ入力します
7) あとは待つだけでできあがりです


5. その他

- DCburn イメージには、公式 NetBSD 5.1 netbsd-GENERIC ELF バイナリーをもとに
  objcopy(1) を使って作成した NetBSD/dreamcast 用 GENERIC カーネルの raw バイナリーが含まれています。
- DCburn イメージには、NetBSD/i386 5.0.2 用 cdrtools-3.00.tgz パッケージバイナリーも含まれています。
  これは ftp.NetBSD.org から取得したものです。


6. 変更履歴

20101114:
 - 最初の公開版

20101121:
 - ホスト名設定を dcserv から dcburn に修正しました (コピペがバレバレ……)

---
Izumi Tsutsui
tsutsui@NetBSD.org
(Japanese translation by kano@. Thanks!)