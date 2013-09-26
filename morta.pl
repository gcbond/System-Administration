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

my @pinghosts = ("8.8.8.8");
my %alive;
my %dead;
my @websites = ("example.com");
while(1) {
    &ping();
    &curl();
    sleep(20);
}
sub date() {
    chomp(my $date = `date +%D`);
    chomp(my $time = `date +%T`);
    return "$date,$time";
}

sub ping() {
    foreach my $hostname (@pinghosts) {
        my $aTime = &date();
        system("ping -c 1 $hostname > /dev/null");
        #The ping failed for some reason
        if($? != 0) {
            $dead{$hostname} = 0 unless exists $dead{$hostname};
            $dead{$hostname}++;
            if(!exists $alive{$hostname}) {
                #This host has never responded to pings...
                print "$hostname has now missed $dead{$hostname} pings\n";
            }
            else {
                my @lastgood = split(",","$alive{$hostname}");
                print "$hostname has now missed $dead{$hostname} pings in a row and was last seen on $lastgood[0] at $lastgood[1]\n";

            }
        }
        #The ping succeeded
        else {
            #Last successful ping was on mm/dd/yy,HH:MM:SS
            $alive{$hostname} = $aTime;
            #The ping worked so reset the fail counter, if it exists.
            $dead{$hostname} = 0 if exists $dead{$hostname};
        }
        sleep(1);
    }
}

sub curl() {
    foreach my $page (@websites) {
        my $aTime = &date();
        my @curl = `curl  -s -m 7 -I $page`;
        if($? != 0) {
            #something when wrong
        }
        #Got a response
        else {
            #200 Codes
            if ($curl[0] =~ /\s2[0-9]{2}\s/) {
                $alive{$page} = $aTime;
                print "Ok! $page\n"
            }
            #300 Codes
            elsif ($curl[0] =~ /\s3[0-9]{2}\s/) {

            }
            #400 Codes
            elsif ($curl[0] =~ /\s4[0-9]{2}\s/) {

            }
            #500 Codes
            elsif ($curl[0] =~ /\s5[0-9]{2]\s/) {

            }
        }
    }
}

sub netcat() {

}

sub pushover() {
    my $title = shift;
    my $message = shift;
    LWP::UserAgent->new()->post(
        "https://api.pushover.net/1/messages.json", [
        "token" => "abc123",
        "user" => "abc123",
        "title" => "$title",
        "message" => "$message",
    ]);
}
