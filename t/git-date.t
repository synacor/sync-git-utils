#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 8;   # Number of tests
use t::PDTest;


my $COMMAND = 'git-date';    # Command to use
my $result;
my $hash1;
my $hash2;
my $hash3;
my $hash4;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

#######################
# Tests dates and times
#######################
`git init; touch temp; git add temp`;
PDTest::commit_time(1246543200);  # 7/2/2009 9:00
`git commit -m "July 2nd"`;

`touch test; git add test`;
PDTest::commit_time(1246561200);  # 7/2/2009 14:00
`git commit -m "Newest July 2nd"`;

`touch new; git add new`;
PDTest::commit_time(1249311600);  # 8/3/2009 10:00
`git commit -m "August 3rd"`;

$result = PDTest::run('"7/2/2009 10:00"');
$hash1  = '14a55f828c456a213dd2866ea96a0ded83d882d3';
like   ($result, qr/$hash1/);

$result = PDTest::run('7/3/2009');
$hash2  = '236c50d146e790640158cf12b50ffc0f1b636d4c';
like   ($result, qr/$hash2/);

$result = PDTest::run('8/4/2009');
$hash3  = '57f562f532427a948e1aa6434f183f8bf0441e29';
like   ($result, qr/$hash3/);

$result = PDTest::run('8/4/2009^');
like   ($result, qr/$hash2/);

$result = PDTest::run('8/4/2009~2');
like   ($result, qr/$hash1/);


##########################
# Test yesterday and today
##########################
`touch yesterday; git add yesterday`;
PDTest::commit_time(time() - 86400);
`git commit -m "Yesterday"`;

`touch today; git add today`;
PDTest::commit_time(time());
`git commit -m "Today"`;

$result = PDTest::run('yesterday');
$hash4  = $result;
unlike   ($result, qr/$hash3/);

$result = PDTest::run('today');
unlike   ($result, qr/$hash4/);

$result = PDTest::run('today^');
like     ($result, qr/$hash4/);


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
