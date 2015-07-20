#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 25; # Number of tests
use t::PDTest;


############################################################
#### Modules ###############################################
############################################################
use Cwd;


my $COMMAND = 'git-ship';  # Command to use
my $result;
my $dir;
my $path;
my $PIPE;
my $output;
my $commit;
my $commit2;
my @commits;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

############################
# Test shipping All Branches
############################
mkdir('remote');
PDTest::set_up_repos();
$dir = getcwd();

chdir('remote');
mkdir('demo.git');
chdir('demo.git');
`git init --bare`;
chdir($dir);

$path = getcwd() . "/remote/demo.git/";

chdir('demo');
$PIPE = PDTest::run_pipe();
print $PIPE "$path\n"; # Path
print $PIPE "0\n";     # All Branches
print $PIPE "\n";      # Continue
print $PIPE "\n";      # Default option for tags
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
like ($output, qr/Where would you like to push this repository:/);
like ($output, qr/Pushing to: $path/);
like ($output, qr/\* 0\. All Branches/);
like ($output, qr/\[All Branches\]/);

chdir('remote/demo.git/');
$result = `git branch -a`;
like ($result, qr/master\n/);
like ($result, qr/dev\n/);
chdir($dir);


##################
# Test --auto flag
##################
chdir('demo');
PDTest::generate_commits(1);
$result = `git log -n 1 --pretty=one`;
($commit) = $result =~ m/(\S*)/;
$PIPE = PDTest::run_pipe('--auto');
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
like ($output, qr/Pushing the following branches:\nAll Branches\n/);

chdir('remote/demo.git/');
$result = `git log -n 1 --pretty=one`;
($commit2) = $result =~ m/(\S*)/;
is ($commit, $commit2);
chdir($dir);


#############################################################
# Test the ship location is remembered and last pushed branch
#############################################################
chdir('demo');
$PIPE = PDTest::run_pipe();
print $PIPE "0\n";     # All Branches
print $PIPE "\n";      # Continue
print $PIPE "\n";      # Default option for tags
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
like ($output, qr/Pushing to: $path/);
like ($output, qr/\* 0\. All Branches/);
like ($output, qr/\[All Branches\]/);


################################
# Test the --clear-branches flag
################################
chdir('demo');
$PIPE = PDTest::run_pipe('--clear-branches');
print $PIPE "\n\n";     # All default options
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
unlike ($output, qr/\* 0\. All Branches/);
unlike ($output, qr/\[All Branches\]/);


###################################
# Test shipping individual branches
###################################
chdir('remote/demo.git/');
`git branch -D dev`;
chdir($dir);

chdir('demo');
$PIPE = PDTest::run_pipe('--clear-branches');
print $PIPE "dev\n";    # dev branch
print $PIPE "\n";       # Continue
print $PIPE "\n";       # Default option for tags
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
like ($output, qr/\* \d\. dev/);
like ($output, qr/\[dev\]/);

chdir('remote/demo.git/');
$result = `git branch -a`;
like ($output, qr/dev\n/);
chdir($dir);


####################
# Test shipping tags
####################
chdir('demo');
$result = `git log -n 10 --pretty=one`;
@commits = split(/\n/, $result);
($commit) = $commits[2] =~ m/(\S*)/;
`git tag awesome-tag $commit`;

$PIPE = PDTest::run_pipe('--clear-branches');
print $PIPE "\n";       # no branches
print $PIPE "y\n";      # push tags
close ($PIPE);
chdir($dir);

chdir('remote/demo.git/');
$result = `git tag`;
like ($result, qr/awesome-tag/);
chdir($dir);


###########################
# Test the --clear-all flag
###########################
chdir('remote');
mkdir('demo-2.git');
chdir('demo-2.git');
`git init --bare`;
chdir($dir);

chdir('demo');
$path = "$dir/remote/demo-2.git";
$PIPE = PDTest::run_pipe('--clear-all');
print $PIPE "$path\n";  # path
print $PIPE "0\n";      # All branches
print $PIPE "\n";       # continue
print $PIPE "\n";       # Default option for tags
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
like ($output, qr/Where would you like to push this repository:/);
like ($output, qr/Pushing to: $path/);

chdir('remote/demo-2.git/');
$result = `git branch -a`;
like ($result, qr/master\n/);
like ($result, qr/dev\n/);
chdir($dir);


#####################
# Test --dry-run flag
#####################
chdir('remote');
mkdir('demo-3.git');
chdir('demo-3.git');
`git init --bare`;
chdir($dir);

chdir('demo');
$path = "$dir/remote/demo-3.git";
$PIPE = PDTest::run_pipe('--clear-all --dry-run');
print $PIPE "$path\n";  # path
print $PIPE "0\n";      # All branches
print $PIPE "\n";       # continue
print $PIPE "\n";       # Default option for tags
close ($PIPE);
chdir($dir);

$output = PDTest::get_output();
like ($output, qr/Where would you like to push this repository:/);
like ($output, qr/Pushing to: $path/);

chdir('remote/demo-3.git/');
$result = `git branch -a`;
unlike ($result, qr/master\n/);
unlike ($result, qr/dev\n/);
chdir($dir);


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
