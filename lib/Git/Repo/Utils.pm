package Git::Repo::Utils;

use strict;
use warnings;

use Env qw(GIT_DIR);
use Exporter;
use Git;

our @ISA = qw(Exporter);
our @EXPORT_OK =
  qw(set_git_dir remote_repo_exists remote_paths_match remote_exists local_branch_checked_out local_branch_exists remote_branch_exists);

sub set_git_dir
{
    my $git_repo = shift;
    my $gd       = $git_repo->command(qw/rev-parse --git-dir/);
    chomp($gd);
    $GIT_DIR = $gd;

    # Make sure GIT_DIR is absolute
    $GIT_DIR = File::Spec->rel2abs($GIT_DIR);
    return 1;
}

sub remote_repo_exists
{
    my $remote_path = shift;
    my @path_parts = split(/:/, $remote_path);
    chomp(my $remote_repo = `ssh $path_parts[0] 'cd $path_parts[1]; git rev-parse --git-dir' 2> /dev/null`);

    if ($remote_repo eq '.' || $remote_repo eq '.git') {
        return 1;
    } elsif ($remote_path !~ /\.git$/) {
        return remote_repo_exists($remote_path . '.git');
    }

    return 0;
}

sub remote_paths_match
{
    my $git_repo       = shift;
    my $remote_name    = shift;
    my $new_remote_url = shift;
    my $old_remote_url = eval { $git_repo->command(qw(config --get-regexp), "^remote\.$remote_name\.url"); };

    chomp($old_remote_url) if $old_remote_url;

    return ($old_remote_url && $old_remote_url =~ /^remote.$remote_name.url $new_remote_url\/?/)
      ;    # extra trailing slash is okay
}

sub remote_exists
{
    my $git_repo    = shift;
    my $remote_name = shift;
    my @results     = eval { $git_repo->command(qw(config --get-regexp), "^remote\.$remote_name\.url"); };
    return (@results == 1);
}

sub local_branch_checked_out
{
    my $git_repo      = shift;
    my $search_branch = shift;

    my @branches = $git_repo->command(qw/branch/);
    my @results = grep { /\* $search_branch/ } @branches;

    return (@results == 1) ? 1 : 0;
}

sub local_branch_exists
{
    my $git_repo      = shift;
    my $search_branch = shift;

    return 0 if !defined($search_branch);

    my @branches = $git_repo->command(qw/branch/);
    my @results = grep { /\s+$search_branch$/ } @branches;

    return (@results == 1) ? 1 : 0;
}

sub remote_branch_exists
{
    my $git_repo      = shift;
    my $remote_name   = shift;
    my $search_branch = shift;

    my @branches = $git_repo->command(qw/branch -r --no-color/);
    my @results = grep { /^\s*$remote_name\/$search_branch$/ } @branches;
    return (@results == 1) ? 1 : 0;
}

1;    # Magic true value required at end of module

__END__

=head1 NAME

Git::Repo::Utils - A bunch of utils for dealing with git repos.

=head1 VERSION

This document describes Git::Repo::Utils version 1.1

=head1 SYNOPSIS

 use Git::Repo::Utils;


=head1 DESCRIPTION


=head1 Comments

This module is just several subs to do some things that are common with coding for git scripts.

=head1 EXPORTS

=over 4

=item set_git_dir ( git_repo )

Given the git_repo object will set the GIT_DIR value in $ENV  properly.

=item remote_repo_exists ( remote_path )

Given a path will make an ssh connection and test for the existence of a git repo at that location.

=item remote_paths_match ( git_repo remote_name new_remote_url )

Tests to see if the given new_remote_url matches the url that is used in the given remote_name.

=item remote_exists ( git_repo remote_name )

Tests for remote existence.

=item local_branch_checked_out ( git_repo search_branch )

Checks to see if the given branch is checked out.

=item local_branch_exists ( git_repo search_branch)

Checks to see if the given branch exists.

=item remote_branch_exists ( git_repo remote_name search_branch )

Checks for the existence of a remote branch.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Michael Canzoneri

