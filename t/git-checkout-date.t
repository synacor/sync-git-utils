#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 5;            # Number of tests
use t::PDTest;


my $COMMAND = 'git-checkout-date';    # Command to use
my $result;


############################################################
#### Set up ################################################
############################################################
PDTest::setup($COMMAND);


############################################################
#### Tests #################################################
############################################################

################################
# Tests checking out to a commit
################################
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
like   ($result, qr/HEAD is now at .* July 2nd/);

`git checkout master > /dev/null 2>&1`;

$result = PDTest::run('7/3/2009');
like   ($result, qr/HEAD is now at .* Newest July 2nd/);

`git checkout master > /dev/null 2>&1`;


################################
# Tests checking out to a branch
################################
PDTest::run('-b new-july 7/3/2009');
$result = `git branch -a`;
like   ($result, qr/new-july/);

`echo 'asfd' >> new; git add new`;
PDTest::commit_time(1249318800);
`git commit -m "Newest August 3rd"`;

PDTest::run('-b new-august 8/4/2009');
$result = `git log --pretty=oneline --abbrev-commit -n 1`;
like   ($result, qr/Newest August 3rd/);

PDTest::run('-b new-august 8/4/2009 master');
$result = `git log --pretty=oneline --abbrev-commit -n 1`;
like   ($result, qr/August 3rd/);


############################################################
#### Teardown ##############################################
############################################################
PDTest::teardown();


__END__

=head1 TESTS

Tests written by Corey Maher

=cut
