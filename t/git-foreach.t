#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 10;     # Number of tests
use t::PDTest;


my $COMMAND = 'git-foreach';    # Command to use
my $result;
my $num;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

################################################
# Tests that git-foreach only works on git repos
################################################
PDTest::set_up_repos();
mkdir('fake');
$result = PDTest::run('pwd');
$num    = ($result =~ s/(demo\s+)/$1/g);
is     ($num, 2);
$num = ($result =~ s/(demo-clone\s+)/$1/g);
is     ($num, 2);
unlike ($result, qr/fake/);


######################
# Tests exclude option
######################
$result = PDTest::run('-e demo pwd');
unlike ($result, qr/demo\s+/);
$num = ($result =~ s/(demo-clone\s+)/$1/g);
is     ($num, 2);


######################
# Tests include option
######################
$result = PDTest::run('-i demo pwd');
unlike ($result, qr/demo-clone\s+/);
$num = ($result =~ s/(demo\s+)/$1/g);
is     ($num, 2);


###############################
# Tests quoting commit messages
###############################
$result = PDTest::run("git commit -m 'quoted greatness'");
$num = ($result =~ s/(working\sdirectory\sclean)/$1/g);
is     ($num, 2);


###############################
# Tests quoting commit messages
###############################
$result = PDTest::run('git commit -m "quoted greatness"');
$num = ($result =~ s/(working\sdirectory\sclean)/$1/g);
is     ($num, 2);


#########################
# Testing common commands
#########################
$result = PDTest::run("git status");
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
