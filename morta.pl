#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  morta.pl
#
#        USAGE:  ./morta.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Grant Bond
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  09/25/2013 09:44:03 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use LWP::UserAgent;
use IO::Socket::INET;
use threads;

my @pinghosts = ("8.8.8.8");
my (%alive, %dead);
my @websites = ("example.com");
my @services = ("mail.br.harvard.edu:25");
my @queue;

#print "Starting threads\n";
my $messenger = threads->create(\&bucket);
my $body = threads->create(\&main);
$_->join() foreach ($messenger, $body);

sub main {
	while(1) {
		&ping();
		&curl();
		&port();
		sleep(5);
	}
}
sub date() {
	chomp(my $date = `date +%D`);
	chomp(my $time = `date +%T`);
	return "$date,$time";
}

sub ping() {
	my @report;
	foreach my $hostname (@pinghosts) {
		#Declare this right away, so we can use it later.
		$dead{$hostname} = 0 unless exists $dead{$hostname};
		my $aTime = &date();
		system("ping -c 1 $hostname > /dev/null");
		#The ping failed for some reason
		if($? != 0) {
			#$dead{$hostname} = 0 unless exists $dead{$hostname};
			$dead{$hostname}++;
			if(!exists $alive{$hostname}) {
				#This host has never responded to pings...
				print "$hostname has now missed $dead{$hostname} pings\n";
			}
			else {
				my @lastgood = split(",",$alive{$hostname});
				print "$hostname has now missed $dead{$hostname} pings in a row and was last seen on $lastgood[0] at $lastgood[1]\n";
				
			}
		}
		#The ping succeeded
		else {
			#Last successful ping was on mm/dd/yy,HH:MM:SS
			$alive{$hostname} = $aTime;
			#The ping worked so reset the fail counter, if it exists.
			#Also the user can stop worrying.
			if($dead{$hostname} != 0) {
				$dead{$hostname} = 0;
				print "$hostname is now responding!\n";
			}
		}
		#sleep(1);
	}
	if(scalar(@report) > 0) {
		#Group messages together and send them
		my $string;
		foreach my $hostname (@report) {
			my @lastgood = split(/,/, $alive{$hostname});
			my $string .= "ICMP: $_ last seen $lastgood[0] @ $lastgood[1]  ";
		}
	}
}

sub curl() {
	foreach my $page (@websites) {	
		$dead{$page} = 0 unless exists $dead{$page};
		my $aTime = &date();
		my @curl = `curl  -s -m 7 -I $page`;
		if($? != 0) {
			#$dead{$page} = 0 unless exists $dead{$page};
			$dead{$page}++;
			if(!exists $alive{$page}) {
				#This site has never responded succesfully.
			}
			else {
				my @lastgood = split(/,/,$alive{$page});
				print "$page has now missed $dead{$page} GETs in a row and was last seen on $lastgood[0] at $lastgood[1]\n";
				#&pushover();
			}
		}
		#Got a response
		else {
			#200 Codes
			if ($curl[0] =~ /\s2[0-9]{2}\s/) {
				$alive{$page} = $aTime;
				print "Ok! $page\n";
				if($dead{$page} != 0) {
					$dead{$page} = 0;
					print "$page is now available (200)\n";
				}
			}
			#300 Codes
			elsif ($curl[0] =~ /\s3[0-9]{2}\s/) {
				#&pushover();
			}
			#400 Codes
			elsif ($curl[0] =~ /\s4[0-9]{2}\s/) {
				#&pushover();
			}
			#500 Codes
			elsif ($curl[0] =~ /\s5[0-9]{2]\s/) {
				#&pushover();
			}
		}
	}
}

sub port() {
	foreach my $service (@services) {
		$dead{$service} = 0 unless exists $dead{$service};
		my $aTime = &date();
		my @hostservice = split(":", $service);
		#Timeout?
		my $sock = IO::Socket::INET->new(	PeerAddr=> $hostservice[0],
											PeerPort=> $hostservice[1],
											Proto 	=> 'tcp',
											Type	=> SOCK_STREAM);
		if($sock) {
			print "$service is open\n";
			$alive{$service} = $aTime;
			if($dead{$service} != 0) {
				$dead{$service} = 0;
				print "$service is now open\n";
			}
		}
		else {
			#$dead{$service} = 0 unless exists $dead{$service};
			$dead{$service}++;
			if(!exists $alive{$service}) {
				#This port was never open.
			}
			else {
				#This port was open but is now closed.
				my @lastgood = split(/,/, $alive{$service});
				print "$service has now missed $dead{$service} connections in a row and was last seen on $lastgood[0] at $lastgood[1]\n";
			}
		}
		close($sock);
	}
}

sub bucket() {
	my $i = 0;
	my $burst = 0;
	while(1) {
		sleep(1);
		if(scalar(@queue) > 0 && $burst <= 3) {
			#Allow up to 3 messages  to be sent ASAP if available
			while(scalar(@queue) > 0 && $burst < 3) {
				my $rawstring = shift @queue;
				my @string = split(/,/, $rawstring);
				&pushover($string[0],$string[1]);
				$burst++;
			}
		}
		if($burst > 0) {
			$i++;
		}
		if($i > 59) {
			$i = 0;
			$burst = 0;
		}
	}	
}

sub pushover() {
	my $title = shift;
	my $message = shift;
	LWP::UserAgent->new()->post(
		"https://api.pushover.net/1/messages.json", [
		"token" => "abc123",
		"user" => "abc123",
		"title" => $title,
		"message" => $message,
	]);
}