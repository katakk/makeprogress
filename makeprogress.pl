#!/usr/bin/perl 

# コンパイル進捗率付きのログ色付き表示フィルタ ETAも表示する

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Storable qw/ nstore retrieve /;
use Cwd qw/getcwd abs_path/;
use Safe;

my $safe = new Safe;
$safe->permit(qw(:default require));
select STDOUT; $| = 1;

my $cwd = $ARGV[0] || getcwd();
my %complieopt = (); ## コンパイルオプションの調査用
my $msgcol = 76;

#
# リーチ精度向上のためゴリ押しでPATH調整
#
my $cwdir =  getcwd() . '/'; 
my $home = $ENV{HOME} . '/'; 
my %reach = (
);

#
# 色構築
my %colour;
$colour{$_}=sprintf "\x1B[38;5;%dm", $_ for(0..255);
$colour{$_ + 256}=sprintf "\x1B[48;5;%dm", $_ for(0..255);

my $fcol = "\x1b[0m\x1b[0;1;3;38;5;251m";
my $red  = "\x1b[0m\x1b[1m" . $colour{196};
my $red2 = "\x1b[0m\x1b[0m" . $colour{202};
my $blue = "\x1b[0m\x1b[0m" . $colour{26}; # 27
my $gren = "\x1b[0m\x1b[0m" . $colour{28}; # 29
my $gray = "\x1b[0m\x1b[0m" . $colour{247};
my $yelw = "\x1b[0m\x1b[0m" . $colour{214};
my $clr  = "\x1b[0m\x1b[0m\x1b[m";

# DB 生成と読み込み と保持
#    ファイルに保持しておこう。
my $progress; # DB
eval { $progress = retrieve('hash.cache') } if(-f 'hash.cache' and -s 'hash.cache');
eval { $progress = &makedb($progress); } ;
eval { nstore $progress, 'hash.cache'; } ;

#  ./makeprogress.pl --colorhelp
#  ./makeprogress.pl --colorhelp --colorall
#  ./makeprogress.pl --colorhelp --colorainbowl
#  ./makeprogress.pl  --dump
#  ./makeprogress.pl  --dump --raw
#
if("@ARGV" =~ m/\-\-colorhelp/ )
{
	if("@ARGV" =~ m/\-\-colorall/ )
	{
		my $stepr = 32;
		my $stepg = 16;
		my $stepb = 32;
		my $line = 0;
		my $n = 3;
		for my $r(0..255/$stepr) {
			for my $g(0..255/$stepg) {

				printf "\n\x1B[0m(%3d:%3d-%3d:%s)", $r * $stepr, $g * $stepg, $g  * $stepg + $n * $stepg, "*" if($line == 0);
				printf "\x1B[38;2;%d:%d:%dm\x1B[7m%d \x1B[0m", $r * $stepr, $g * $stepg, $_ * $stepb, $_ * $stepb for(0..255/$stepb);
				$line = 0 if($line++ > $n);
			}
		}
		printf "\n";
	}
	
	if("@ARGV" =~ m/\-\-colorainbowl/ )
	{
		sub rainbow
		{
			foreach(@_)
			{
					my $line = 0;
					my $n = 20;
				my $step = 10;
				my ($r, $g, $b) = @{$_};
				my $p = sprintf "%d:%d:%d", $r, $g, $b; # parette
				printf "\n\x1B[0m(%3d:%3d:%3d)", $r, $g, $b;
				printf "\x1B[38;2;%d:%d:%dm\x1B[7m \x1B[0m", $r, $g, $b;
				for my $t(0..255/$step) {
					my $tmp = $p;
					$t *= $step;
					$tmp =~ s/0/$t/g;
					if($t >= 160)
					{
					printf "\x1B[48;2;%sm %-3s \x1B[0m", $tmp, $t ;
					}
					else
					{
					printf "\x1B[38;2;%sm\x1B[7m %-3s \x1B[0m", $tmp, $t ;
					}
					last if($line++ > $n);
				}
			}
		}
		&rainbow(
			[qw/255   0   0/], [qw/255 127   0/], [qw/255 255   0/], [qw/127 255   0/], 
			[qw/  0 255   0/], [qw/  0 255 127/], [qw/  0 127 255/], [qw/  0   0 255/], 
			[qw/127   0 255/], [qw/255   0 255/], );
	}

	sub palette
	{
		foreach(@_)
		{
			printf "%-4s", ((/x/) ? '' : sprintf $colour{$_} . "\x1B[7m %-3s \x1B[0m", $_) foreach(grep { $_ = abs($_) % 256 unless(/x/) } @$_);
			print "\n";
			printf "%-4s", ( (/x/) ? '' : sprintf $colour{$_+256} .   " %-3s \x1B[0m", $_) foreach(grep { $_ = abs($_) % 256 unless(/x/) } @$_);
			print "\n";
		}
	}

	sub palette2
	{
		foreach(@_)
		{
			print "   external  ";
			foreach(@$_)
			{
				$_ = 15 if(/x/) ;
				if( $_ < 0 )
				{
					$_ = abs($_);
					if( $_ > 256 )
					{
						printf $colour{$_ - 256} . "\x1B[7m %-3s \x1B[0m", $_;
					}
					else
					{
						printf $colour{$_ + 256} . " %-3s \x1B[0m", $_;
					}
				} else {
					if( $_ > 256 )
					{
						printf $colour{$_} . " %-3s \x1B[0m", $_;
					}
					else
					{
						printf $colour{$_} . "\x1B[7m %-3s \x1B[0m", $_;
					}
				}
			}
			print "\n";
		}
		print "\n";
	}
	&palette2(
	[qw/ 0    0    0    0    233  22   233  0    232  0    0    0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    0    0    0    22   47   10   40   22   232  0    0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    0    0    0    35   47   10   28   232  0    0    0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    0    0    0    48   48   47   10   34   233  0    0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    0    0    48   48   47   10   82   70   22   0    0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    0    42   48   47   10   82   118  154  112  58   0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    42   48   47   83   118  154  190  184  58   0    0    0    0    0    0    0    0    0    0   /],
	[qw/ 0    35   49   48   47   83   119  155  154  190  11   184  58   232  0    0    0    0    0    0   /],
	[qw/ 0    23   49   48   84   120  155  191  227  11   220  178  58   232  0    0    0    0    0    0   /],
	[qw/ 234  49   85   84   120  156  192  228  227  221  220  214  172  94   232  0    0    0    0    0   /],
	[qw/ 43   50   49   85   121  157  193  229  228  222  221  215  208  94   232  0    0    0    0    0   /],
	[qw/ 30   50   86   122  158  194  230  229  223  222  216  215  209  208  202  94   232  0    0    0   /],
	[qw/ 234  14   123  159  158  194  255  230  224  223  217  216  210  209  203  202  88   232  0    0   /],
	[qw/ 0    6    14   87   123  159  195  255  225  224  218  217  211  210  204  203  197  9    88   232 /],
	[qw/ 0    23   45   81   117  153  189  225  218  211  205  204  198  197  9    88   232  0    0    0   /],
	[qw/ 0    38   45   39   75   111  147  183  219  212  206  205  198  197  161  125  88   52   0    0   /],
	[qw/ 0    23   39   75   105  141  177  213  206  205  199  198  161  89   52   233  0    0    0    0   /],
	[qw/ 0    25   39   33   69   12   105  141  171  207  13   200  199  198  125  89   52   232  0    0   /],
	[qw/ 0    232  32   33   63   99   135  171  165  13   200  199  162  89   53   233  0    0    0    0   /],
	[qw/ 0    234  27   63   99   93   129  165  13   200  127  89   53   232  0    0    0    0    0    0   /],
	[qw/ 0    17   27   21   57   93   129  165  128  91   53   234  0    0    0    0    0    0    0    0   /],
	[qw/ 0    233  19   57   93   91   54   53   232  0    0    0    0    0    0    0    0    0    0    0   /],
	)  if(0);

	&palette2(
	[qw/   x   x   x   151 114 151 252 15  /],
	[qw/   x   254 41  10  10  10  10  10  77  114 255 15 /],
	[qw/   x   77  47  47  10  10  10  10  10  10  10  77  151 15 /],
	[qw/   254 47  47  47  47  47  10  10  10  10  10  10  10  40  114 255 15 /],
	[qw/   152 48  47  47  47  47  47  47  47  10  10  10  10  10  10  10  77  253 15 /],
	[qw/   151 48  48  48  47  47  47  47  47  47  47  10  10  10  10  10  10  82  113 253 15 /],
	[qw/   152 48  48  48  48  48  48  47  47  47  47  47  47  47  10  10  82  82  118 118 149 253 15 /],
	[qw/   252 48  48  48  48  48  48  48  48  48  47  47  47  47  47  47  83  118 118 154 154 190 185 253 15 /],
	[qw/   254 48  49  49  49  48  48  48  48  48  48  48  48  48  47  83  83  119 155 154 190 190 11  220 185 253 15 /],
	[qw/   x   43  49  49  49  49  49  49  49  49  49  48  48  48  48  84  120 156 155 191 227 227 11  220 220 214 179 253 15 /],
	[qw/   x   79  50  49  49  49  49  49  49  49  49  49  49  49  85  121 156 156 192 228 228 221 221 221 214 214 214 208 179 253 15 /],
	[qw/   x   152 50  50  50  50  50  50  50  50  50  50  50  85  121 157 157 193 229 229 222 222 215 215 215 209 209 208 208 208 173 188 15 /],
	[qw/   x   255 44  50  50  50  50  50  50  50  50  50  50  86  122 158 194 230 229 223 223 216 216 210 209 209 209 209 203 202 202 202 173 252 15 /],
	[qw/   x   x   80  14  14  14  14  14  14  14  14  14  87  123 159 195 15  224 224 217 217 216 210 210 210 203 203 203 203 203 203 197 9   9   167 252 15 /],
	[qw/   x   x   252 45  45  45  45  45  45  45  45  45  81  117 153 189 225 218 218 217 211 211 204 204 204 204 204 203 197 197 197 197 197 197 9   9   167 181 15 /],
	[qw/   x   x   x   74  45  45  45  45  45  45  45  75  111 147 183 183 219 219 212 212 205 205 205 204 198 198 198 198 198 197 197 197 197 197 197 161 167 174 254 15 /],
	[qw/   x   x   x   152 39  39  39  39  39  39  39  75  111 141 177 177 213 213 206 206 205 199 199 199 198 198 198 198 198 198 198 162 169 181 254 15 /],
	[qw/   x   x   x   x   74  39  33  33  33  33  69  12  105 135 171 171 207 207 200 200 200 199 199 199 199 199 198 169 175 182 255 15 /],
	[qw/   x   x   x   x   255 32  33  33  27  27  63  99  135 135 165 165 13  13  200 200 200 199 163 169 176 253 15 /],
	[qw/   x   x   x   x   x   252 27  27  27  63  57  93  129 129 165 165 13  13  170 170 182 255 15 /],
	[qw/   x   x   x   16  17  18  19 20  21  57  93  93  129 129 170 176 182 15  x   x   x   x   x  x  x   x  0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15 /],
	[qw/   x   x   x   x   16   17   18  19 98  92  134 176 254  15 x   x   x  232  233  234  235  236  237  238  239  240  241  242  243  244  245 246 247 248 249 250 251 252 253 254 255   /],
    );

	&palette2(
	[qw/  0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  /],
	[qw/ 232  233  234  235  236  237  238  239  240  241  242  243  244  245 -246 -247 -248 -249 -250 -251 -252 -253 -254 -255  /],
	[qw/-488 -489 -490 -491 -492 -493 -494 -495 -496 -497 -498 -499  500  501  502  503  504  505  506  507  508  509  510  511  /],
	[qw/ 202  203  204  205  206  207  219  218  217  216  215  214 -226 -227 -228 -229 -230 -231 /],
	[qw/ 166  167  168  169  170  171  183  182  181  180  179  178  190 -191 -192 -193 -194 -195 /],
	[qw/ 130  131  132  133  134  135  147  146  145  144  143  142  154  155 -156 -157 -158 -159 /],
	[qw/ 94   95   96   97   98   99   111  110  109  108  107  106  118  119  120  121 -122 -123 /],
	[qw/ 58   59   60   61   62   63   75   74   73   72   71   70   82   83   84   85   86  -87  /],
	[qw/ 22   23   24   25   26   27   39   38   37   36   35   34   46   47   48   49   50   51  /],
	[qw/ 16   17   18   19   20   21   33   32   31   30   29   28   40   41   42   43   44   45  /],
	[qw/ 52   53   54   55   56   57   69   68   67   66   65   64   76   77   78   79   80  -81  /],
	[qw/ 88   89   90   91   92   93   105  104  103  102  101  100  112  113  114  115 -116 -117 /],
	[qw/ 124  125  126  127  128  129  141  140  139  138  137  136  148  149 -150 -151 -152 -153 /],
	[qw/ 160  161  162  163  164  165  177  176  175  174  173  172  184 -185 -186 -187 -188 -189 /],
	[qw/ 196  197  198  199  200  201  213  212  211  210  209  208 -220 -221 -222 -223 -224 -225 /],
	);

	&palette2(
	[qw/ 151 114 151 252 /],
	[qw/ 41  10  10  10  10  10  77  114  /],
	[qw/ 77  47  47  10  10  10  10  10  10  10  77  151  /],
	[qw/ 47  47  47  47  47  10  10  10  10  10  10  10  40  114/],
	[qw/ 48  47  47  10  10  10  10  10  10  10  77  /],
	[qw/ 48  48  48  47  47  10  10  10  10  10  10  82  113  /],
	[qw/ 48  48  48  47  47  47  47  47  10  10  82  82  118 118 149 253  /],
	[qw/ 48  48  48  48  47  47  47  47  47  47  83  118 118 154 154 190 185 253  /],
	[qw/ 48  49  49  48  48  48  48  48  47  83  83  119 155 154 190 190 220 185 253 15 /],
	[qw/ 43  49  49  49  49  48  48  48  48  84  120 156 155 191 227 227 220 220 214 179 253 15 /],
	[qw/ 79  50  49  49  49  49  49  49  85  121 156 156 192 228 228 221 221 221 214 214 214 208 179 /],
	[qw/ 50  50  50  50  50  50  85  121 157 157 193 229 229 222 222 215 215 215 209 208 173 188 /],
	[qw/ 44  50  50  50  50  50  86  122 158 194 230 229 223 223 216 216 210 209 203 202 202 202 173 /],
	[qw/ 80  14  14  87  123 159 195 224 224 217 217 216 210 210 210 203 203 203 197 9   9   167 /],
	[qw/ 45  45  45  81  117 153 189 225 218 218 217 211 211 204 204 203 197 9   9   167 181 /],
	[qw/ 74  45  75  111 147 183 183 219 219 212 212 205 205 205 204 198 198 197 161 167 174 /],
	[qw/ 74  39  39  39  39  75  111 141 177 177 213 213 206 206 205 199 198 198 162 169 181 /],
	[qw/ 74  39  33  33  33  33  69  12  105 135 171 171 207 207 200 200 200 199 199  199 198 169 175 182  /],
	[qw/ 32  33  33  27  27  63  99  135 135 165 165 13  13  200 200 200 199 163 169 176  /],
	[qw/ 22  23  24  25  26  27  63  57  93  129 129 165 165 13  13  170 170 182  /],
	[qw/ 16  17  18  19 20  21  57  93  93  129 129 170 176 182   /],
	[qw/ 16  16   17   18  19 98  92  134 176/], 
	) if(0);
	print "\n";

	exit;
}

if("@ARGV" =~ m/\-\-dump/ )
{
	print Dumper $progress if("@ARGV" =~ m/\-\-raw/ )
	&dumpdb($progress);
	exit;
}

&main();


#
# プログレス表示のためのログ解析とDB生成
# 精度は不明。統計による。
sub makedb
{
	my $prog = shift;
	
	my $t_min = 25*3600;
	my $t_max = -1;
	my %tmp = ();
	while(<DATA>)
	{
		chomp;
		next if(/^#/);
		s/CC\ \[M\]/CC/;
		s/LD\ \[M\]/LD/;
#		$_ = substr( $_, 0, $msgcol); # split ETA
		next unless(/^(\d+):(\d+):(\d+)\s+(\w+)\s+([^\s]+)/);
		my($h, $m, $s, $kind, $locate) = ($1, $2, $3, $4, $5);
		next unless($h);
		next unless($m);
		next unless($s);
		my $t = $h * 3600 + $m * 60 + $s;
		next unless($t);
		$t_min = $t if( $t < $t_min );
		$t_max = $t if( $t > $t_max );
		next unless($kind=~ m/(IKCFG|CC|MK_FW|HOSTCC|LD|CALL|Making|
		                       GEN|SHIPPED|Delete|LDS|GZIP|SYSMAP|
		                       UPD|MKELF|TIMEC|AS|KSYM|UIMAGE|AR|
		                       HOSTLD|Generating|OBJCOPY|Complie|
		                       LOGO|CONMK)/);
		next unless($locate);
		# 微調整
		next if($locate =~ /include\/generated\/compile\.h/);
		next if($locate =~ /built-in\.o$/);
		next if($locate =~ /init\/version\.o$/);
		next if($locate =~ /.*\.mod\.c$/);
		next if($locate =~ /.*\.mod\.o$/);
		next if($locate =~ /.*\.ko$/);	
		$tmp{$kind}{$locate} = $t;
#	print;
#	print "\n";
	}
#	die;
	unless($t_max - $t_min)
	{
		print STDERR "\x1b[0m\x1b[7m" . $colour{205} . "LOG ERROR!! (max:$t_max - min:$t_min) will illegal division by zero\n";
		return $prog;
	}
	
	# min - max とれたので ETA 再計算
	foreach my $kind(keys %tmp)
	{
		foreach my $locate(keys %{$tmp{$kind}})
		{
			my $t = $tmp{$kind}{$locate};
			$$prog{$kind}{$locate}{tim} = ($t_max - $t_min) - ($t - $t_min);
			$$prog{$kind}{$locate}{per} =  ($t - $t_min) * 100 /  ($t_max - $t_min);
		}
	}
	return $prog;
}

#
#
#
sub dumpdb
{
	my $progress = shift;
	my @b = ();
	foreach my $kind(keys %$progress)
	{
		foreach my $locate(keys %{$$progress{$kind}})
		{
			my $p = $$progress{$kind}{$locate}{per};
			my $t = $$progress{$kind}{$locate}{tim};
			push @b, sprintf '%22s %8s %-16s %-s' . "\n",
			   (sprintf '%03.16f', $p),
			   (sprintf '(%02d:%02d)', $t / 60 , $t % 60),
			    $kind, $locate;
		}
	}
	
	print sort @b;
}

#
# 絶対パスを検索
#
sub abspath
{
	my $path = shift;
	my $apath = abs_path($path);
	unless($apath)
	{
		my $tmp = $cwd . '/' . $path;
		$apath = abs_path($tmp);

	}
	$apath = $apath || $path;
	($apath =~ m/^$cwdir/) ? $apath =~ s/^$cwdir// : $apath =~ s/^$home//;
#print $red . "reach{$apath}:$reach{$apath} cw:$cwdir ($apath)" . $clr . "\n";
	$apath = $reach{$apath} if($reach{$apath});
	($apath =~ m/^$cwdir/) ? $apath =~ s/^$cwdir// : $apath =~ s/^$home//;
	return $apath;
}

#
# 進捗率付きのログ表示機構
#
#   ここでもDB構築したいけど、エンドがわかんないのでダメだね
#
my $dp = 0;
my $dt = 0;
sub printlog
{
	my ($fmt, $kind, $locate, $progress) = @_;
				my $prog = undef;
	
	if($kind and $locate)
	{
		my ($rkind) = $kind;
		($rkind) = $1 if($kind =~ m/([^\s]+)/);
		my ($rlocate) = $locate;
		($rlocate) = $1 if($locate =~ m/\ ([^\s]+)$/);

		if($rkind and $rlocate)
		{
			my $p = $$progress{$rkind}{$rlocate}{per};
			my $t = $$progress{$rkind}{$rlocate}{tim};
	
			if($p and $t)
			{
				# make -j switch のためのごり合わせ
				# でもログ取得は一度 make -j 1 しなくちゃだめ
				if($dp and $dp != 0 and $dp > $p)
				{
					$p = $dp;
					$t = $dt;
				} else {
					$dp = $p;
					$dt = $t;
				}
				
				## ETA 表示してみる。
				my @a= localtime;
				my $a = $t + $a[2] * 3600 +  $a[1] * 60 + $a[0];
				$prog = sprintf $gray . "[%3.2f%%] ETA %02d:%02d.(%02d:%02d)" ,
				$p,
				$a / 3600 % 60, $a / 60 % 60,
				$t / 60, $t % 60;

			}
		}
	}

#	print "\x1B[48;5;255m" if( $. & 1 );

	if($prog)
	{
		printf $fmt, $locate, $prog;
	}
	else {
		print $locate;
	}
	return;
}

#
# 時間表示
#
sub local_time
{
	my @a= localtime;
	sprintf $fcol . "%02d:%02d:%02d" . $clr , $a[2], $a[1], $a[0];
}

#
# メイン処理ルーチン
#
#         標準入力からパースする
#
sub main
{

	while(<>)
	{
		chomp;

		my @ar = split( / /, $_ );
		my @ar0 = split( /:/, $ar[0] || '' );
		if( $#ar0 > 1 )
		{
			$ar0[0] = abs_path($ar0[0]);
			$ar[0] = shift @ar0;
			$ar[0] .= ' +';
			$ar[0] .= shift @ar0;
			$ar[0] .= ' :';
			$ar[0] .= join( ':' , @ar0 );
		}

#print $red . "0:$ar[0] 1:$ar[1] 2:$ar[2] 3:$ar[3] 4:$ar[4] 5:$ar[5] 6:$ar[6] 7:$ar[7] 8:$ar[8] 9:$ar[9]" . $clr . "\n";

		my $kind = '';

		$ar[0] ||= '';
		$ar[1] ||= '';
		$ar[3] ||= '';

		$kind = "$ar[2] $ar[3]" if($ar[2]);
		$ar[2] ||= '';
		my $ars = "$ar[0] $ar[1] $ar[2] ";
		if($ars =~ m/\-?cc / or $ars =~ m/\/?cc /  or $ars =~ m/^gcc / or $ars =~ m/^cc / )
		{
			$kind = 'Complie'
		}
		elsif($ars =~ m/\-ld / or $ars =~ m/\/ld /  or $ars =~ m/^ld / )
		{
			$kind = 'Link   ';
		}
		elsif($ars =~ m/rm /)
		{
			$kind = 'Delete ';
		}
# NOT PARSE MODPOSt!!
#	elsif($ars =~ m/modpost /)
#	{
#		$kind = 'ModPost ';
#	}

		$_ = join( ' ', @ar );

		if($kind eq 'Complie')
		{
			my $cnt=0;
			my $skip=3;
			foreach(@ar)
			{
				next if($skip++ == 1); # if skip=1  skip-next
				next if($cnt++ < 2);

				## コンパイルオプションの解析 (OPTIONAL)
				next if(m/^$/);
				next if(m/^\-W/);
				next if(m/^\-I/);
				next if(m/^\-l/);
				next if(m/^\\/);
				next if(m/^\|/);
				next if(m/^\-D\"KBUILD_BASENAME=KBUILD_STR\(/);
				next if(m/^\-D\"KBUILD_MODNAME=KBUILD_STR\(/);
				next if(m/^\-D\"KBUILD_STR\(/);
				
				do{ $skip=1; next; } if(m/^\-c$/);
				do{ $skip=1; next; } if(m/^\-g$/);
				do{ $skip=1; next; } if(m/^\-o$/);
				do{ $skip=1; next; } if(m/^\-include$/);
				do{ $skip=1; next; } if(m/^\-isystem$/);
				
				next if(m/\.o$/);
				next if(m/\.h$/);
				next if(m/\.c$/);
				next if(m/\.S$/);
				$complieopt{$_}++;
			}

			foreach(@ar)
			{
				next unless(m/\.c$/);
				print &local_time() . " ";
				print $blue . "    $kind ";
				&printlog( '%-' . ($msgcol + 0) . 's %s', $kind, &abspath($_), $progress);

				last;				
			}
		}
		elsif($kind eq 'Link   ')
		{
			foreach(@ar)
			{
				next unless(m/\.ko$/);
				print &local_time() . " ";
				print $red2 . "    $kind ";
				print &abspath($_);

				last;
			}
		}
		elsif($kind eq 'Delete ')
		{
			for my $i(2..$#ar)
			{
				$_ = $ar[$i];
				next unless ($_);
				next if /^\-/;
				#		next unless -f;

				print &local_time() . " ";
				print $red2 . "    $kind ";
				print &abspath($_);
				print "\n";
				last;
			}
			#	$_ =a join( ' ', @ar );
			#	last;
		}
		elsif($kind eq 'ModPost ')
		{
			print &local_time() . " ";
			print $red2 . "    $kind ";
			print ;
		}
		else
		{
		
			my $pendingbuff = &local_time() . " ";

			if($kind =~ m/CC/ or $kind =~ m/LD/)
			{
				for my $i(5..7)
				{
					next unless ($ar[$i]);
					$ar[$i] = &abspath($ar[$i]);
				}
				$_ = join( ' ', @ar );
			}


			$pendingbuff .= $blue if($kind =~ m/AS/ );
			$pendingbuff .=  $blue if($kind =~ m/CC/ );
			$pendingbuff .=  $red2 if($kind =~ m/LD/ );
			$pendingbuff .=  $gray if($kind =~ m/LD/ and m/\/built-in\.o/ );
			$pendingbuff .=  $gren if($kind =~ m/GZIP/ );
			$pendingbuff .=  $gren if($kind =~ m/IKCFG/ );
			$pendingbuff .=  $gren if($kind =~ m/CONMK/ );
			$pendingbuff .=  $gren if($kind =~ m/TIMEC/ );
			$pendingbuff .=  $gren if($kind =~ m/GEN/ );
			$pendingbuff .=  $gren if($kind =~ m/UPD/ );
			$pendingbuff .=  $gren if($kind =~ m/CALL/ );
			$pendingbuff .=  $gren if($kind =~ m/LOGO/ );
			$pendingbuff .=  $gren if($kind =~ m/SHIPPED/ );
			$pendingbuff .=  $gren if($kind =~ m/MK_FW/ );
			$pendingbuff .=  $gren if($kind =~ m/CHK/ );
			$pendingbuff .=  $gren if($ar[1] =~ m/warning/i);
			$pendingbuff .=  $gren if($ar[1] =~ m/note/i);
			$pendingbuff .=  $red if($ar[1] =~ m/error/i);
			$pendingbuff .=  $red if($ar[0] =~ m/WARNING/i);

			# incompatible implicit declaration of built-in function
			$pendingbuff .=  $yelw if($ar[1] =~ m/warning/ and 
				$ar[2] =~ m/incompatible/ and $ar[3] =~ m/implicit/ and
				 $ar[4] =~ m/declaration/ and $ar[5] =~ m/of/ and
				 $ar[6] =~ m/built-in/ and $ar[7] =~ m/function/ );
			
			next if( $ars =~ /\(cat\ \/dev\/null;/);
			$pendingbuff .=  $gray if( $ars =~ /make/);
			$pendingbuff .=  $gren if( $ars =~ /scripts\/mod\/modpost/);
			if( $ars =~ /scripts\/mod\/modpost/)
			{
				my $modpost_i = '';
				my $modpost_o = '';
				$modpost_i = $1 if( "@ar" =~ m/\-i\s+([^\s]+)?\s+/);
				$modpost_o = $1 if( "@ar" =~ m/\-o\s+([^\s]+)?\s+/);
				$_ = "  MODPOST $modpost_i => $modpost_o";
			}
			
			print $pendingbuff;
			&printlog('%-' . ($msgcol + 12) . 's %s', $kind, $_, $progress);
		}

		print $clr . "\n";
	}

	if("@ARGV" =~ /\-\-dispoption/)
	{
		if(keys %complieopt)
		{
			my $cnt = 0;
			print "\x1b[1m\x1b[0;7;32m" . "are compile options ...\n";
			foreach(sort keys %complieopt)
			{
				printf $gren . "%-35s". $clr . " ", $_ ;
				if( ++$cnt > 3)
				{
					$cnt = 0;
					print "\n";
				}
			}
			
			print $clr . "\n";
		}
	}
}



## ログ貼っっける。ビルドログ解析してプログレス表示ぅー
## Storable でシリアライズ毎回してるので一度hash.cache作ったら消してもOK
__END__

