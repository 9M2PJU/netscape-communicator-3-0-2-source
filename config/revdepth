#! /usr/local/bin/perl

use FindBin;
unshift(@INC, $FindBin::Bin);

require "$FindBin::Bin/fastcwd.pl";

$cur = &fastcwd;
chdir($ARGV[0]);
$newcur = &fastcwd;
$newcurlen = length($newcur);

# Skip common separating / unless $newcur is "/"
$cur = substr($cur, $newcurlen + ($newcurlen > 1));
print $cur;
