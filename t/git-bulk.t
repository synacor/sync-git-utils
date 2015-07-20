#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 10;     # Number of tests
use t::PDTest;


my $COMMAND = 'git-bulk';       # Command to use
my $result;
my $expected;
my $num;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

#############################################
# Tests that git-bulk only works on git repos
#############################################
PDTest::set_up_repos();
mkdir('fake');
$result = PDTest::run('branch -a');
like   ($result, qr/\/demo\s+/);
like   ($result, qr/\/demo-clone\s+/);
unlike ($result, qr/fake/);


##########################################
# Test that it fails properly with no args
##########################################
$result = PDTest::run();
$expected = <<'EOS';
Usage:
     git bulk [GIT_COMMAND]
              [-i repo1,repo2,...] [GIT_COMMAND]
              [-e repo1,repo2,...] [GIT_COMMAND]

EOS
is     ($result, $expected);


######################
# Tests exclude option
######################
$result = PDTest::run('-e demo branch -a');
unlike ($result, qr/\/demo\s+/);
like   ($result, qr/\/demo-clone\s+/);


######################
# Tests include option
######################
$result = PDTest::run('-i demo branch -a');
like   ($result, qr/\/demo\s+/);
unlike ($result, qr/\/demo-clone\s+/);


###############################
# Tests quoting commit messages
###############################
$result = PDTest::run("commit -m 'quoted greatness'");
$num = ($result =~ s/(working\sdirectory\sclean)/$1/g);
is     ($num, 2);


###############################
# Tests quoting commit messages
###############################
$result = PDTest::run('commit -m "quoted greatness"');
$num = ($result =~ s/(working\sdirectory\sclean)/$1/g);
is     ($num, 2);


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
