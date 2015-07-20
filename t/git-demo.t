#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 16;     # Number of tests
use t::PDTest;


############################################################
#### Modules ###############################################
############################################################
use Cwd;


my $COMMAND = 'git-demo';       # Command to use
my $result;
my $repo;
my @lines;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

####################################################
# Tests if the basic flag sets up a repo and a clone
####################################################
PDTest::run();
ok     (-d 'demo');
ok     (-d 'demo-clone');

chdir('demo');
$repo   = cwd();
$result = `git status 2>&1`;
unlike ($result, qr/fatal:/);
chdir('..');

chdir('demo-clone');
$result = `git status 2>&1`;
unlike ($result, qr/fatal:/);
chdir('..');


########################################
# Tests if demo-clone is a clone of demo
########################################
chdir('demo-clone');
$result = `git remote -v`;
like   ($result, qr{origin\s+$repo});
chdir('..');


###########################################
# Tests if the correct branches are created
###########################################
chdir('demo');
$result = `git branch -a`;
like   ($result, qr/dev/);
like   ($result, qr/master/);
chdir('..');

chdir('demo-clone');
$result = `git branch -a`;
like   ($result, qr/master/);
like   ($result, qr/testing/);
like   ($result, qr/origin\/HEAD/);
like   ($result, qr/origin\/dev/);
like   ($result, qr/origin\/master/);
chdir('..');


###########################
# Tests moar-commits option
###########################
mkdir('moar');
chdir('moar');
`git init`;
PDTest::run('--moar-commits 11');
$result = `git log --pretty=oneline --abbrev-commit`;
@lines = split/\n/, $result;
is     (@lines, 11);
chdir('..');


########################
# Tests directory option
########################
PDTest::run('--moar-commits 2 --directory moar');
chdir('moar');
$result = `git log --pretty=oneline --abbrev-commit`;
@lines = split/\n/, $result;
is     (@lines, 13);
chdir('..');

PDTest::run('--directory blah');
ok     (-d 'blah');
ok     (-d 'blah-clone');


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
