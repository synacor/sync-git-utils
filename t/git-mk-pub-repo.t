#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 10;      # Number of tests
use t::PDTest;


############################################################
#### Modules ###############################################
############################################################
use Cwd;
use File::Path;

my $COMMAND = 'git-mk-pub-repo'; # Command to use
my $result;
my $path;
my $dir;
my $name;
my $location;

############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

#####################
# Tests basic command
#####################
PDTest::set_up_repos();
mkdir('remote');
$dir  = getcwd();
$path = $dir . '/remote';

chdir('demo');
PDTest::run("--location $path");
chdir($dir);

ok (-d "$path/demo.git/");

chdir('demo');
$result = `git remote -v`;
($name, $location) = $result =~ m/(.*)\t(.*)/;
is ($name, "$ENV{'USER'}_local");
is ($location, "$path/demo.git (fetch)");
chdir($dir);


################
# Test auto flag
################
chdir('demo-clone');
PDTest::run("--location $path --auto");
chdir('../remote/demo-clone.git/');
$result = `git branch -a`;
like ($result, qr/master\n/);
like ($result, qr/testing\n/);
chdir($dir);


####################
# Test --push option
####################
rmtree('demo', 0);
rmtree('demo-clone', 0);
rmtree('remote', 0);
mkdir('remote');

PDTest::set_up_repos();
chdir('demo');
PDTest::run("--location $path --auto --push all");
chdir('../remote/demo.git/');
$result = `git branch -a`;
like ($result, qr/dev\n/);
like ($result, qr/master\n/);
chdir($dir);


################################
# Test passing specific branches
################################
chdir('demo-clone');
PDTest::run("--location $path --auto testing");
chdir($dir);
chdir('remote/demo-clone.git/');
$result = `git branch -a`;
like   ($result, qr/testing\n/);
unlike ($result, qr/master\n/);
chdir($dir);


####################
# Test remote option
####################
rmtree('demo', 0);
rmtree('demo-clone', 0);
rmtree('remote', 0);
mkdir('remote');

PDTest::set_up_repos();
chdir('demo');
PDTest::run("--location $path --remote publish");
$result = `git remote -v`;
($name, $location) = $result =~ m/(.*)\t/;
is ($name, 'publish');


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
