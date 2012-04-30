#!/usr/bin/perl

use strict;
use warnings;

my %servers;

my @input = `rpcinfo -b 100005 2`;
foreach(@input) {
	my @fields = split(/\s+/, $_);
	$servers{$fields[0]} = 1 unless $servers{$fields[0]};
}
for my $ip(keys %servers) {
	my @shares = `showmount -e $ip`;
	foreach(@shares) {
		print "$_";
	}
	print "\n";
}