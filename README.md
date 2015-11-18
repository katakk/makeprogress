# makeprogress

コンパイル終わらないにゅ・・・

いつ釈放されるんだにゅ・・・

と言った場合に、進捗率付きのログ色付き表示フィルタ

ETAも表示できるのでコンパイル中にうんこできます。


# インストール

    $ chmod 755  makeprogress.pl
    $ sudo cp -p makeprogress.pl /usr/bin/

# 使い方

一度、ビルドして時間とビルドログを採取します。

    $ cd /usr/src/linux-4.1.12-gentoo/
    $ make clean
    $ make 2>&1 | makeprogress.pl | tee log

ビルド時間をhash.cacheにキャッシュします。

    $ cp /usr/bin/makeprogress.pl .
    $ cat log | perl -ple 'chop; s/\033\[.+?m//g;' | col -bx >> ./makeprogress.pl
    $ perl ./makeprogress.pl
    ^C
    $ rm ./makeprogress.pl

その後のビルドはETAが表示されるのでビルドしている時間はうんこできます。

    $ make 2>&1 | makeprogress.pl
    00:21:08   CHK     include/config/kernel.release
    00:21:08   CHK     include/generated/uapi/linux/version.h
    00:21:08   CHK     include/generated/utsrelease.h
    00:21:08   CHK     include/generated/bounds.h
    00:21:08   CHK     include/generated/asm-offsets.h
    00:21:08   CALL    scripts/checksyscalls.sh                 [99.44%] ETA 00:29.(08:04)
    00:21:09   CHK     include/generated/compile.h
    00:21:09   CC      init/calibrate.o                         [99.46%] ETA 00:28.(07:48)
    00:21:09   CC      init/init_task.o                         [99.46%] ETA 00:28.(07:48)
    00:21:09   LD      init/built-in.o
    00:21:09   HOSTCC  usr/gen_init_cpio                        [99.46%] ETA 00:28.(07:47)
    00:21:09   GEN     usr/initramfs_data.cpio.gz
    00:21:09   AS      usr/initramfs_data.o                     [99.46%] ETA 00:28.(07:46)
    00:21:09   LD      usr/built-in.o
    00:21:09   LD      arch/x86/crypto/built-in.o
    00:21:09   CC      arch/x86/kernel/process_32.o             [99.46%] ETA 00:28.(07:46)
    00:21:10   CC      arch/x86/kernel/signal.o                 [99.46%] ETA 00:28.(07:44)
    00:21:10   AS      arch/x86/kernel/entry_32.o               [99.46%] ETA 00:28.(07:43)
    00:21:10   CC      arch/x86/kernel/traps.o                  [99.46%] ETA 00:28.(07:43)

やったねたえちゃん、零時二十八分までうんこできるよ！！

# デバッグのヒント

hash.cacheデータベースのダンプは下記の方法で可能です。

    $ makeprogress.pl --dump
        0.0000000000000000 (1439:56) CC               mm/slub.o
        0.0057873049678226 (1439:51) CC               mm/migrate.o
        0.0081022269549516 (1439:49) CC               mm/early_ioremap.o
        0.0092596879485161 (1439:48) CC               fs/open.o
        0.0115746099356452 (1439:46) CC               fs/read_write.o
        :   
       99.9930552340385930  (00:06) CC               mm/swap_state.o
       99.9953701560257002  (00:04) CC               mm/swapfile.o
       99.9988425390064037  (00:01) CC               mm/dmapool.o
      100.0000000000000000  (00:00) CC               mm/hugetlb.o


利用可能は色は下記コマンドで確認してね

    $ makeprogress.pl --colorhelp --colorall

# 仕様・制限

- perlで書いているのでこれ自体が重いという説があるのでだれかCで書き直してね

- 文字列の比較でどのコンパイル位置にいるかを想定しています。

- `make -j 4` とかでビルドするとETAずれます。

- `make V=1`でのビルドはETA計算対象じゃないみたい。冗長なログを抑えます。

