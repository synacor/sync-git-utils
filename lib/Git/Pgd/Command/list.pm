package Git::Pgd::Command::list;

use base qw(App::Cmd::Simple);

use strict;
use warnings;

use Data::Dumper;
use Git::Repo::Locator;

sub opt_spec
{
    return (["show-git-root|s", "Print the root of the git repos"],
            ["list|l",      "Simple list of repos"],
            ["include|i=s", "Repos to include"],
            ["exclude|e=s", "Repos to exclude"],
           );
}

sub validate_args
{
    my ($self, $opt, $args) = @_;

    # no args allowed but options!
    $self->usage_error("No args allowed") if @$args;
}

sub execute
{
    my ($self, $opt, $args) = @_;

    my $locator = Git::Repo::Locator->new();

    if ($opt->{'show_git_root'}) {
        print $locator->find_git_root() . "\n";
        exit;
    }

    my $locator_opts;

    if ($opt->{'include'}) {
        my @split = split(',', $opt->{'include'});
        $locator_opts->{'include'} = \@split;
    }

    if ($opt->{'exclude'}) {
        my @split = split(',', $opt->{'exclude'});
        $locator_opts->{'exclude'} = \@split;
    }

    if ($locator_opts) { $locator->set_include_exclude(%{$locator_opts}); }
    my $repos = $locator->repo_list();

    foreach my $repo (sort keys %{$repos}) {
        if ($opt->{'list'}) {
            print $repo . "\n";
        } else {
            print $repos->{$repo} . "\n";
        }
    }
}

=head1 NAME
 
Git::Pgd::Command::list - Lists the full paths to local git repos. (Default)
 
=head1 VERSION

This document describes Git::Pgd::Command::list version 1

=head1 SYNOPSIS

 git pgd < (-i | -e ) repo1,repo2 > < --list > < --show-git-root >

=head1 DESCRIPTION 

Lists the full paths to local git repos.

=head1 EXPORTS

=over 4
 
=item opt_spec

GetOpt::Long::Descriptive options sub.

=item validate_args

Validates the arguments.

=item execute

Executes the main part of the command.

=back
 
=head1 EXAMPLES

 git pgd
 git pgd -i repo1,repo2
 git pgd -l

=head1 BUGS AND LIMITATION

None Reported.

=head1 MUSINGS
 
None.

=head1 AUTHOR
 
Mike Canzoneri
 
=head1 SEE ALSO
 
None.
 
=cut

1;
