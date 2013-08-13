#!/usr/bin/perl
# Grant Bond
# Parse Get-VMSummary (Using modules from http://pshyperv.codeplex.com/)

use warnings;
use strict;

die "Please specify the file as an arugment!\n" unless defined($ARGV[0]);

my $filepath = $ARGV[0];

open (FILE, $filepath);

my ($cpuCount, $snapshots, $os, $uptime, $cpuLoadHistory, $host, $ip, $fqdn, $cpuLoad, $born, $state, $name, $memoryUse, $guid);
my %vms = {};
#Read the file line by line
while(<FILE>) {
	chomp($_);
	if($_ =~ m/^CPUCount/) {
		$_ =~ s/^CPUCount\s+:\s?//g;
		$cpuCount = $_;
	}
	elsif($_ =~ m/^Snapshots/) {
		$_ =~ s/^Snapshots\s+:\s?//g;
		$snapshots = $_;
	}
	elsif($_ =~ m/^GuestOS/) {
		$_ =~ s/^GuestOS\s+:\s?//g;
		$os = $_;
	}
	elsif($_ =~ m/^UptimeFormatted/) {
		$_ =~ s/^UptimeFormatted\s+:\s?//g;
		$uptime = $_;
	}
	elsif($_ =~ m/^CPULoadHistory/) {
		$_ =~ s/^CPULoadHistory\s+:\s?//g;
		$cpuLoadHistory = $_;
	}
	elsif($_ =~ m/^Host/) {
		$_ =~ s/^Host\s+:\s?//g;
		$host = $_;
	}
	elsif($_ =~ m/^IpAddress/) {
		$_ =~ s/^IpAddress\s+:\s?//g;
		$ip = $_;
	}
	elsif($_ =~ m/^VMElementName/) {
		$_ =~ s/^VMElementName\s+:\s?//g;
		$name = $_;
	}
	elsif($_ =~ m/^FQDN/) {
		$_ =~ s/^FQDN\s+:\s?//g;
		$fqdn = $_;
	}
	elsif($_ =~ m/^CPULoad/) {
		$_ =~ s/^CPULoad\s+:\s?//g;
		$cpuLoad = $_;
	}
	elsif($_ =~ m/^CreationTime/) {
		$_ =~ s/^CreationTime\s+:\s?//g;
		my $year = substr $_, 0, 4;
		my $month = substr $_, 4, 2;
		my $day = substr $_, 6, 2;
		my $tHour = substr $_, 8, 2;
		my $tMin = substr $_, 10, 2;
		$born = "$month/$day/$year $tHour:$tMin";
	}
	elsif($_ =~ m/^EnabledState/) {
		$_ =~ s/^EnabledState\s+:\s?//g;
		$state = $_;
	}
	elsif($_ =~ m/^Name/) {
		$_ =~ s/^Name\s+:\s?//g;
		$guid = $_;
	}
	elsif($_ =~ m/^MemoryUsage/) {
		$_ =~ s/^MemoryUsage\s+:\s?//g;
		$memoryUse = $_;
		#Since we are going line by line this is the last field
		my @summary = ($host, $name, $state, $cpuCount, $cpuLoadHistory, $memoryUse, "", $snapshots, $born,);
		$vms{$guid} = \@summary;
	}
}

close(FILE);

my @columns = ("Host", "VM Name", "State", "Cores", "CPU Load", "RAM", "Disk", "Snapshots", "Created");
printf "%-15s%-30s%-10s%-8s%-20s%-20s%-20s%-20s%-40s\n", @columns;

foreach my $vm (values %vms) {
	if(defined($vm)) {
		my @array = @$vm;
		printf "%-15s%-30s%-10s%-8s%-20s%-20s%-20s%-20s%-40s\n", @array;	
	}
}