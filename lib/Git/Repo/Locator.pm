package Git::Repo::Locator;

use strict;
use warnings;

use Data::Dumper;
use Git;
use Cwd;
use File::Basename qw(basename dirname);
use File::Spec;
use Config::INI::Reader;

our $VERSION = 0.02;

sub new
{
    my ($class, %args) = @_;

    my $self = bless({}, $class);

    $self->{'pgd_file'} = '.gitpgd';
    $self->{'git_root'} = $self->find_git_root();

    return $self;
}

sub set_include_exclude
{
    my ($self, %args) = @_;

    if ($args{'include'}) { $self->{'include'} = $args{'include'}; }
    if ($args{'exclude'}) { $self->{'exclude'} = $args{'exclude'}; }
}

sub repo_list
{
    my $self = shift;

    $self->load_local_config();

    my $found_git_dirs = $self->find_git_dirs();

    $self->resolve_include_exclude_args();

    my $execute_dirs = $self->derive_execute_dirs($found_git_dirs);

    return $execute_dirs;
}

sub derive_execute_dirs
{
    my $self           = shift;
    my $found_git_dirs = shift;

    my @include;
    my @exclude;
    my %execute_dirs;

    if ($self->{'include'}) { @include = @{$self->{'include'}}; }
    if ($self->{'exclude'}) { @exclude = @{$self->{'exclude'}}; }

    map { $execute_dirs{basename($_)} = File::Spec->rel2abs($_); } @{$found_git_dirs};

    if (@include > 0) {
        my %temp_dirs;
        map { (exists($execute_dirs{$_})) ? $temp_dirs{$_} = $execute_dirs{$_} : warn("$_ is not a valid repo!"); }
          @{$self->{'include'}};
        %execute_dirs = %temp_dirs;
    }

    if (@exclude > 0 && @include == 0) {
        map { (exists($execute_dirs{$_})) ? delete $execute_dirs{$_} : warn("$_ is not a valid repo!"); }
          @{$self->{'exclude'}};
    }

    return \%execute_dirs;

}

sub load_local_config
{
    my $self = shift;

    if (-f $self->{'git_root'} . '/' . $self->{'pgd_file'}) {
        $self->{'local_config'} = Config::INI::Reader->read_file($self->{'git_root'} . '/' . $self->{'pgd_file'});
    }
}

sub resolve_include_exclude_args
{
    my $self = shift;

    my $local_config;

    if ($self->{'local_config'}) {
        $local_config = $self->{'local_config'};
    }

    my @include;
    my @exclude;

    if ($self->{'include'}) {
        @include = map { basename($_); } @{$self->{'include'}};    # kill trailing slash

        if (exists $local_config->{'groups'}) {
            @include = @{repo_group_expansion(\@include, $local_config->{'groups'})};
        }

        $self->{'include'} = \@include;
        delete $self->{'exclude'} if (defined $self->{'exclude'});
    } else {
        if ($self->{'exclude'}) {
            @exclude = map { basename($_); } @{$self->{'exclude'}};    # kill trailing slash
        }

        if (exists $local_config->{'_'}->{'exclude'}) {
            push(@exclude, split(' ', $local_config->{'_'}->{'exclude'}));
        }

        if (@exclude && exists $local_config->{'groups'}) {
            @exclude = @{repo_group_expansion(\@exclude, $local_config->{'groups'})};
        }

        $self->{'exclude'} = \@exclude;
    }
}

sub repo_group_expansion
{
    my $repos  = shift;
    my $groups = shift;

    my %repos_struct;
    @repos_struct{@{$repos}} = undef;

    foreach my $group (keys %{$groups}) {
        if (exists $repos_struct{$group}) {
            delete($repos_struct{$group});
            my @group_repos = split(/\s/, $groups->{$group});
            push(@group_repos, @{repo_group_expansion(\@group_repos, $groups)});
            @repos_struct{@group_repos} = undef;
            @{$repos} = keys(%repos_struct);
        }
    }

    return $repos;
}

sub find_git_dirs
{
    my $self     = shift;
    my $orig_dir = cwd();
    my @git_dirs;

    my @found_dirs = `find $self->{'git_root'} -follow -type d -maxdepth 1 -mindepth 1 2>/dev/null`;

    push(@found_dirs, $self->{'git_root'});    # This is for bare repo support

    chomp(@found_dirs);
    @found_dirs = map { my $temp = $_; $temp =~ s/\/\.git//; $temp; } @found_dirs;

    @found_dirs = map { File::Spec->rel2abs($_); } @found_dirs;

    foreach my $dir (@found_dirs) {
        chdir($dir);
        chomp(my $git_dir = `git rev-parse --git-dir 2>/dev/null`);
        if ($git_dir eq '.' || $git_dir eq '.git') {
            push(@git_dirs, $dir);
        }
    }

    # no .gitpgd?  not in repo root?  no problem!
    if (scalar(@git_dirs) == 0) {
        push(@git_dirs, $self->find_git_above());
        chomp(@git_dirs);
    }

    chdir($orig_dir);
    return \@git_dirs;
}

sub find_dir
{
    my $self = shift;
    my $target = shift;
    return unless $target;
    my $is_dir = (substr($target,-1,1) eq '/');

    my $dir = cwd();
    do {
        return $dir if ($is_dir ? -d "$dir/$target" : -f "$dir/$target");
    } while (($dir = dirname($dir)) ne '/');
    return;
}

sub find_git_root
{
    my $self = shift;
    return $self->find_dir($self->{'pgd_file'}) || cwd();
}

sub find_git_above
{
    my $self = shift;
    return $self->find_dir('.git/');
}

=head1 NAME
 
Git::Repo::Locator - Locate local git repos
 
=head1 VERSION

This document describes Git::Repo::Locator version 1

=head1 SYNOPSIS

 $locator = Git::Repo::Locator->new();
 $result_hash = $locator->repo_list();

=head1 DESCRIPTION 

Locate local git repos

=head1 PUBLIC METHODS

=over 4
 
=item new

Create new Git::Repo::Locator object. 

=item set_include_exclude ( 'include' => \@repos_to_include, 'exclude' => \@repos_to_exclude )

Takes the given list of repos and either includes or excludes those repos
from the operations of the rest of the module.

=item find_git_root

Returns the root location of the git repos.

=item repo_list

Returns a hash of repos and their full paths.

=back

=head1 PRIVATE METHODS

=over 4
 
=item load_local_config

Searches for a local .gitpgd file and attempts to load it.

=item find_git_dirs

Returns an array of the full paths to the git repos that are in the git root.

=item find_git_above

Returns the path to the git repo that is above the current working directory.

=item find_dir

Searches up the directory tree, starting at the current working directory, until
it finds a directory that contains either a target file or directory.

If the argument given ends in a '/', find_dir looks for a target directory.
Otherwise, it looks for a target file.

=item derive_execute_dirs

Validates that repos exist, calculates the basename, and calclulates what repos 
should be returned based off of include and exclude options.

=item resolve_include_exclude_args

Resolves any issues that come from having include and exclude options set.
Also resolves any long path issues and passes the groups off to
B<repo_group_expansion>.

=item repo_group_expansion

Expands a group to the full list of repos based off of the config
info in the B<.gitpgd> file.

=back

=head1 EXAMPLES

 $locator = Git::Repo::Locator->new();
 $repos = $locator->repo_list();

 $git_root = $locator->find_git_root;

 @include_array = ('path/to/repo', 'repo2');
 $locator->set_include_exclude('include' => \@include_array);
 $repos = $locator->repo_list();

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
