#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Fcntl qw(:flock);

my $q = CGI->new;
print $q->header;

my $file = 'entries.txt';
my $bans = 'banned_ips.txt';
my $ip = $ENV{'REMOTE_ADDR'};
my $action = $q->param('action') || '';
my $name = $q->param('name') || '';
my $msg = $q->param('message') || '';
my $cap = $q->param('captcha') || '';
my $cap_answer = $q->param('cap_answer') || '';
my $page = $q->param('page') || 1;

if (-e $bans) {
    open my $ban, '<', $bans;
    while (<$ban>) {
        chomp;
        if ($_ eq $ip) {
            print "<p>you are banned from this guestbook.</p>"; # change this if you want custom error messages
            exit;
        }
    }
    close $ban;
}

if ($action eq 'post') {
    if ($cap != $cap_answer) {
        print "<p>you cant do math? <a href='?'>try again</a></p>"; # change this if you want custom error messages

        exit;
    }
    $name =~ s/\R//g;
    $msg =~ s/\R//g;
    open my $fh, '>>', $file;
    flock $fh, LOCK_EX;
    print $fh "$name|$msg|$ip\n";
    close $fh;
    print "<p>entry posted. <a href='?'>back</a></p>"; # change this if you want custom error messages
    exit;
}

open my $fh, '<', $file;
my @lines = reverse <$fh>;
close $fh;

my $per_page = 5;
my $total = scalar @lines;
my $pages = int(($total + $per_page - 1) / $per_page);
$page = 1 if $page < 1;
$page = $pages if $page > $pages;
my $start = ($page - 1) * $per_page;

print "<h1>Guestbook</h1>";
my $a = int(rand(10)) + 1;
my $b = int(rand(10)) + 1;
print "<form method='POST'><input type='hidden' name='action' value='post'>";
print "Name: <input name='name'> Message: <input name='message'>";
print "What is $a + $b? <input name='captcha'><input type='hidden' name='cap_answer' value='".($a+$b)."'>";
print "<input type='submit' value='Post'></form>";

for my $i ($start .. $start + $per_page - 1) {
    last if $i >= @lines;
    my ($n, $m, $ipaddr) = split(/\|/, $lines[$i], 3);
    $n = CGI::escapeHTML($n);
    $m = CGI::escapeHTML($m);
    print "<p><b>$n:</b> $m</p>";
}

print "<p>Page: ";
for my $p (1..$pages) {
    if ($p == $page) {
        print " [$p] ";
    } else {
        print " <a href='?page=$p'>$p</a> ";
    }
}
print "</p>";
print "<p><a href='admin.pl'>admin</a></p>";
