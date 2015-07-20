#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 19; # Number of tests
use t::PDTest;


############################################################
#### Modules ###############################################
############################################################
use Cwd;


my $COMMAND = 'git-pgd';    # Command to use
my $result;
my $expected;
my $cur_dir;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

########################################
# Tests a directory with no repositories
########################################
is     (PDTest::run(), '');
like   (PDTest::run('-e asdf'), qr/asdf is not a valid repo!/);
like   (PDTest::run('-i asdf'), qr/asdf is not a valid repo!/);

$cur_dir = cwd();
like   (PDTest::run('--show-git-root'), qr/$cur_dir\n/);


#
# Tests a directory with 2 repositories
#
PDTest::set_up_repos();

############
# Basic Test
############
$result = PDTest::run();
like   ($result, qr/\/var\/tmp\/.*?\/demo\n/);
like   ($result, qr/\/var\/tmp\/.*?\/demo-clone\n/);


##########################
# Test Exclude and Include
##########################
$result = PDTest::run('-e demo');
like   ($result, qr/\/var\/tmp\/.*?\/demo-clone\n/);
unlike ($result, qr/\/var\/tmp\/.*?\/demo\n/);

$result = PDTest::run('-i demo');
like   ($result, qr/\/var\/tmp\/.*?\/demo\n/);
unlike ($result, qr/\/var\/tmp\/.*?\/demo-clone\n/);


##############################
# Test the -show-git-root flag
##############################
$result = PDTest::run('--show-git-root');
like   ($result, qr/$cur_dir\n/);

# After moving to a different directory
chdir('demo');
$result = PDTest::run('--show-git-root');
like   ($result, qr/$cur_dir\/demo\n/);
chdir($cur_dir);

# With a .gitpgd file
`touch .gitpgd`;
chdir('demo');
$result = PDTest::run('--show-git-root');
like   ($result, qr/$cur_dir\n/);
chdir($cur_dir);


##############################
# Test exclude list in .gitpgd
##############################
`echo 'exclude = demo' > .gitpgd`;
$result = PDTest::run();
unlike ($result, qr/\/var\/tmp\/.*?\/demo\n/);
like   ($result, qr/\/var\/tmp\/.*?\/demo-clone\n/);

`echo 'exclude = demo demo-clone' >> .gitpgd`;
$result = PDTest::run();
unlike ($result, qr/\/var\/tmp\/.*?\/demo\n/);
unlike ($result, qr/\/var\/tmp\/.*?\/demo-clone\n/);


######################################
# Test that include works over exclude
######################################
$result = PDTest::run('-i demo');
like ($result, qr/\/var\/tmp\/.*?\/demo\n/);

unlink '.gitpgd';


####################
# Test the list flag
####################
$result   = PDTest::run('--list');
$expected = <<'EOS';
demo
demo-clone
EOS
is ($result, $expected);


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();

__END__

=head1 TESTS

Tests written by Corey Maher

=cut
