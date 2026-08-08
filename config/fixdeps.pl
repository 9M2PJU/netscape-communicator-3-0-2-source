#!/usr/bin/perl

use strict;
use warnings;

my ($dependencies, $target, $objdir, $make) = @ARGV;

die "fixdeps.pl: expected dependency file, target, object directory, and make command\n"
    unless defined $make;

open(my $md, '<', $dependencies) or do {
    # A missing included dependency file is normal on the first build.
    exit 0 if $target eq $dependencies;
    die "$make: *** No rule to make target $target.  Stop.\n";
};

local $/;
my $contents = <$md> // '';
close($md);

my $target_pattern = quotemeta($target);
if ($contents =~ / \.*\/*$target_pattern /) {
    print "Removing stale dependency $target from $dependencies\n";
    $contents =~ s/ \.*\/*$target_pattern / /g;

    my $tmpname = "$objdir/fix.md$$";
    open(my $tmp, '>', $tmpname) or die "$make: cannot write $tmpname: $!\n";
    if (!print {$tmp} $contents) {
        close($tmp);
        unlink($tmpname);
        exit 1;
    }
    close($tmp) or do {
        unlink($tmpname);
        exit 1;
    };

    if (!rename($tmpname, $dependencies)) {
        unlink($tmpname);
    }
} elsif ($target ne $dependencies) {
    die "$make: *** No rule to make target $target.  Stop.\n";
}

exit 0;
