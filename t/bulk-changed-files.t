#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 9;            # Number of tests
use t::PDTest;


my $COMMAND = 'bulk-changed-files';   # Command to use
my $result;
my $num;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

###########################################################################
# Tests that bulk-changed-files reports the correct number of changed files
###########################################################################

#
# Creates a git repo with 10 commits then creates 3 clones of it.
# Makes one commit on one (3 file changes), 10 commits on two (should update all 5 files),
# and makes no commits on three.
#
mkdir('repo');
chdir('repo');
`git init`;
PDTest::generate_commits(10);
chdir('..');
mkdir('clones');
`git clone repo clones/one`;
`git clone repo clones/two`;
`git clone repo clones/three`;
chdir('clones');
chdir('one');
PDTest::generate_commits(1);
chdir('../two/');
PDTest::generate_commits(10);
chdir('..');

$result = PDTest::run();
$num    = ($result =~ s/(one\/)/$1/g);
is     ($num, 3);

$num = ($result =~ s/(two\/)/$1/g);
is     ($num, 5);

unlike ($result, qr/three\//);


##################
# Test -i argument
##################
chdir('three');
PDTest::generate_commits(3);
chdir('..');
$result = PDTest::run('-i one,three');
like   ($result, qr/one\//);
unlike ($result, qr/two\//);
like   ($result, qr/three\//);


##################
# Test -e argument
##################
$result = PDTest::run('-e one');
unlike ($result, qr/one\//);
like   ($result, qr/two\//);
like   ($result, qr/three\//);


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
