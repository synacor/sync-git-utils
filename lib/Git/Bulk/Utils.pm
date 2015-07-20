package Git::Bulk::Utils;

use strict;
use warnings;

use Git;
use File::Basename qw(basename);

sub new
{
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    $self->{base_bulk_cmd} = 'git bulk -q';

    if (exists $args{'pgd_args'}) { $self->{base_bulk_cmd} .= ' ' . join(' ', @{$args{'pgd_args'}}); }

    return $self;
}

sub parse_bulk_output
{
    my $self   = shift;
    my $output = shift;
    my %results;
    my $key;
    chomp(@{$output});

    foreach my $line (@{$output}) {
        if ($line =~ /([\/\w+\W+]+)\s-\s/) {
            $key = basename($1);
            $results{$key} = undef;
        } else {
            push(@{$results{$key}}, $line);
        }
    }
    return \%results;
}

sub sanatize
{
    my $self        = shift;
    my $bulk_output = shift;

    foreach my $repo (keys %{$bulk_output}) {
        if (grep(/fatal/, @{$bulk_output->{$repo}}) > 0) {
            delete $bulk_output->{$repo};
        }
    }

    return $bulk_output;
}

sub checked_out_branches
{
    my $self           = shift;
    my @bulk_buffer    = `$self->{base_bulk_cmd} symbolic-ref HEAD`;
    my %branch_results = %{parse_bulk_output($self, \@bulk_buffer)};

    foreach my $repo (keys %branch_results) {
        @{$branch_results{$repo}} = basename(@{$branch_results{$repo}}[0]);
    }

    return \%branch_results;
}

sub unbranched_repos
{
    my $self        = shift;
    my $branch      = shift;
    my @bulk_buffer = `$self->{base_bulk_cmd} branch`;

    return repos_without_regex($self, $branch . '$', \@bulk_buffer);
}

sub branched_repos
{
    my $self        = shift;
    my $branch      = shift;
    my @bulk_buffer = `$self->{base_bulk_cmd} branch`;

    return repos_with_regex($self, $branch . '$', \@bulk_buffer);
}

sub dirty_repos
{
    my $self   = shift;
    my @status = `$self->{base_bulk_cmd} status`;
    return repos_with_regex($self, '(Changes\sto\sbe\scommitted|Changed\sbut\snot\supdated)', \@status);
}

sub repos_without_regex
{
    return _process_repo_regex(shift, shift, shift, 1);
}

sub repos_with_regex
{
    return _process_repo_regex(shift, shift, shift);
}

sub _process_repo_regex
{
    my $self        = shift;
    my $regex       = shift;
    my $bulk_output = shift;
    my $invert      = shift;
    my @missing_repos;

    my $bulk_repos = parse_bulk_output($self, $bulk_output);

    foreach my $repo (keys %{$bulk_repos}) {
        if ($invert) {
            push(@missing_repos, $repo) unless (grep { /$regex/ } @{$bulk_repos->{$repo}});
        } else {
            push(@missing_repos, $repo) if (grep { /$regex/ } @{$bulk_repos->{$repo}});
        }
    }

    return @missing_repos;
}

=head1 NAME
 
Git::Bulk::Utils - This module provides utilites for using L<git-bulk> 
output in your scripts.  It provides some methods that will call 
L<git-bulk> directly and some will take output from L<git-bulk> 
and return formated hashes.
 
=head1 VERSION

This document describes Git::Bulk::Utils version 1

=head1 SYNOPSIS

    my $bulk_util   = Git::Bulk::Utils->new('pgd_args' => \@pgd_args);
    my @bulk_buffer = `git bulk @pgd_args -q diff origin/master... --name-only`;
    my $results     = $bulk_util->parse_bulk_output(\@bulk_buffer);

=head1 DESCRIPTION 

After creating L<git-bulk> it became clear that we needed a module
that could deal with the output from L<git-bulk> and return a hash.  Once
that was complete some additional subs were added for common problems.  These
include finding out which repos have a specific branch or whether a set of
repos had any uncommitted work in tracked files.

=head1 PUBLIC METHODS

=over 4
 
=item new ( 'pgd_args' => "-i repo1" )

Create a new Git::Bulk::Utils object.  The object can optionally take an
array of L<git-pgd> arguments that it will pass along to L<git-pgd> in the
event that a sub is called that uses it.

=item parse_bulk_output ( $bulk_output ) 

Accepts the raw output of L<git-bulk> and returns a hash of the form:

 {'repo1' => ('line1','line2','line3'), 'repo2' => ('line1','line2')}

=item sanatize ( \%parsed_bulk_output )

Accepts a properly formatted hash that would be produced by B<parse_bulk_output>.
Currently it only strips out error that contain the word 'fatal'.

 my $results = $bulk_util->parse_bulk_output(\@bulk_buffer);
 $results = $bulk_util->sanatize($results);

=item checked_out_branches

When called checked_out_branches returns a hash with each repos as the key and the currently checked out
branch as the value.

 {'repo1' => ('beta-branch'), 'repo2' => ('dev-branch')}

=item unbranched_repos ( $branch )

When passed a branch name as an argument unbranched_repos will return a list of repos
that do not contain that branch.

=item branched_repos ( $branch )

When passed a branch name as an argument branched_repos will return a list of repos
that contain that branch.

=item dirty_repos

When called dirty_repos will return a list of repos that have uncommitted work
in tracked files.

=item repos_without_regex ( $regex, $raw_bulk_output )

repos_without_regex accepts a regex and raw B<git-bulk> output and properly
passes it to _process_repo_regex.  A list of repos that do not contain the regex
will be returned.

=item repos_with_regex ( $regex, $raw_bulk_output )

repos_with_regex accepts a regex and raw B<git-bulk> output and properly
passes it to B<_process_repo_regex>.  A list of repos that contain the regex
will be returned.

=item _process_repo_regex ( $regex, $raw_bulk_output, [ $invert ] )

_process_repo_regex accepts a regex, raw B<git-bulk> output, and optionally an invert value.
The content of the raw L<git-bulk> output is run through B<parse_bulk_output> and then we loop
through each repo to see if it matched the regex.  By default it will return the repos that match
the regex.  If passed the invert flag it will return the repos that do not match.  This is a private
method.

=back
 
=head1 EXAMPLES

See above.

=head1 BUGS AND LIMITATION

None Reported.

=head1 MUSINGS
 
None.

=head1 AUTHOR
 
Mike Canzoneri
 
=head1 SEE ALSO
 
None.
 
=cut

1;    # Magic true value required at end of module
