#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Fcntl qw(:flock);

my $q = CGI->new;
print $q->header;

my $pwfile = 'admin_password.txt'; # change admin_password.txt if u want to set your password
my $file = 'entries.txt';
my $banfile = 'banned_ips.txt';
my $action = $q->param('action') || '';
my $pass = $q->param('pass') || '';

if ($action eq '' || $action eq 'auth') {
    if ($pass eq '') {
        print "<form method='POST'><input type='hidden' name='action' value='auth'>";
        print "<input type='password' name='pass'><input type='submit' value='login'></form>";
        exit;
    }
    open my $pf, '<', $pwfile;
    chomp(my $real = <$pf>);
    close $pf;
    if ($pass ne $real) {
        print "<p>Wrong password. <a href='admin.pl'>Try again</a></p>";
        exit;
    }
    show_panel($pass);
    exit;
}

if ($action eq 'delete') {
    my $id = $q->param('id');
    open my $fh, '<', $file;
    my @lines = <$fh>;
    close $fh;
    @lines = reverse @lines;
    splice(@lines, $id, 1);
    @lines = reverse @lines;
    open $fh, '>', $file;
    flock $fh, LOCK_EX;
    print $fh @lines;
    close $fh;
    print "<p>Deleted. <a href='admin.pl?action=auth&pass=$pass'>Back</a></p>";
    exit;
}

if ($action eq 'ban') {
    my $id = $q->param('id');
    open my $fh, '<', $file;
    my @lines = <$fh>;
    close $fh;
    @lines = reverse @lines;
    my ($n, $m, $ipaddr) = split(/\|/, $lines[$id], 3);
    chomp($ipaddr);
    open my $ban, '>>', $banfile;
    flock $ban, LOCK_EX;
    print $ban "$ipaddr\n";
    close $ban;
    print "<p>Banned $ipaddr. <a href='admin.pl?action=auth&pass=$pass'>Back</a></p>";
    exit;
}

sub show_panel {
    my ($p) = @_;
    open my $fh, '<', $file;
    my @lines = reverse <$fh>;
    close $fh;
    print "<h1>Admin Panel</h1>";
    for my $i (0..$#lines) {
        my ($n, $m, $ipaddr) = split(/\|/, $lines[$i], 3);
        $n = CGI::escapeHTML($n);
        $m = CGI::escapeHTML($m);
        chomp $ipaddr;
        print "<p><b>$n:</b> $m [$ipaddr] ";
        print "<a href='?action=delete&id=$i&pass=$p'>[delete]</a> ";
        print "<a href='?action=ban&id=$i&pass=$p'>[ban IP]</a></p>";
    }
    print "<p><a href='guestbook.pl'>Back to Guestbook</a></p>";
}
