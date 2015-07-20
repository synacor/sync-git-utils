package Git::FixRemotes;
use warnings;
use strict;

use base qw(App::Cmd::Simple);
use Config::General qw( ParseConfig );
use Git;
use Error qw(:try);
use Sys::Hostname;
use Data::Dumper;

=head1 NAME

Git::FixRemotes - Update a git repo's remotes to match defined patterns

=head1 SYNOPSIS

See documentation for the git-fix-remotes command

=cut

=head1 FUNCTIONS

=over 4

=item opt_spec

Configure available options, per the App::Cmd examples

=cut

sub opt_spec
{
	return (
		[ 'noop|n',  "Do not make any changes, but show what action would be taken" ],
		[ 'remote|r=s',  "Modify only this remote" ],
		[ 'verbose|v',  "Print more output, showing what change goes with what remote" ],
	);
}

=item usage_desc

Configure usage help message, per the App::Cmd examples

=cut

sub usage_desc
{
	return "git [bulk] fix-remotes [-v] [-n]";
}

=item validate_args

Validate arguments per the App::Cmd examples.  Well, validate that there aren't any.

=cut

sub validate_args
{
    my ($self, $opt, $args) = @_;

    $self->usage_error("No args allowed") if @$args;
}

=item execute

The main function as called by git-fix-remotes when the command is run.

=cut

sub execute
{
    my ($self, $opt, $args) = @_;

	my %config = ParseConfig( -ConfigFile => '/etc/git-fix-remotes.conf' );
	
	# Rearrange the data structure for matching
	for my $g_name ( keys %{$config{'Group'}} )
	{
		my $g_data = $config{'Group'}->{$g_name};
	
		for my $matchtype ( qw (LocalHost RemoteHost) ) {
			push @{$g_data->{'Match_' . $matchtype}},
				map {
					$_ =~ s/$matchtype\s+//; $_
				} grep /^$matchtype\s/, @{$g_data->{'Match'}};
		}

		map {
			my $path = $_;
			map {
				$path->{$_} = ref($path->{$_}) ?
					{
						preferred  => $path->{$_}->[0],
						all        => [ @{$path->{$_}} ],
					} :
					{
						preferred  => $path->{$_},
						all        => [ $path->{$_} ],
					};
			} keys %$path
		} values %{$g_data->{'Path'}};
	
		delete $g_data->{'Match'};

		$g_data->{'Pattern'} = [ $g_data->{'Pattern'} ] unless ref($g_data->{'Pattern'});
		@{$g_data->{'Pattern'}} = map {
			if ( /^(\w+)\s+(.+)$/ )
			{
				$g_data->{'Pattern_Args'}->{$1} = $2;
				$1;
			}
			else
			{
				$_;
			}
		} @{$g_data->{'Pattern'}};
	}

	my $repo = Git->repository();
	
	my @cmdout = $repo->command('remote', '-v');

	foreach my $remote ( @cmdout )
	{
		my @buffer;
		my $indent='';

		my $retval = _handle_remote(\%config, $opt, $repo, $remote, \@buffer, \$indent);

		if ( $opt->{'verbose'} )
		{
			if ( defined($retval) )
			{
				print $retval ? "[OK]\n" : "[FAIL]\n";
			}
			else
			{
				print "...\n";
			}
		}

		map {
			print $indent . $_ . "\n";
		} @buffer;
	}
}

sub _handle_remote
{
	my ($config, $opt, $repo, $remote, $buffer, $indent) = @_;

	my $retval;
	my ($r_name, $r_url, $r_dir);
	my ($r_user, $r_host, $r_port, $r_path, $r_type);

	# Match one output line from 'git remote -v'
	if ( $remote =~ /^([\w-]+)\s+(.+)\s+\((push|fetch)\)$/ )
	{
		($r_name, $r_url, $r_dir) = ($1, $2, $3);
		printf "%-70s", (
			sprintf "%-12s %s (%s) ", $r_name, $r_url, $r_dir
		) if $opt->{'verbose'};
	}
	else
	{
		print STDERR "git-remote output: $remote not matched\n";
		return 0;
	}

	return 1 if defined($opt->{remote}) && $r_name ne $opt->{remote};

	$$indent = (' ' x (length($r_name) > 12 ? length($r_name) : 12) ) . ' ' if $opt->{'verbose'};

	# GIT style URL
	if ( $r_url =~ /^
		git:\/\/
		([a-zA-Z0-9-.]+)	# 1 host
		(:[0-9]+)?			# 2 :port
		(.+)?				# 3 path
		/x
	)
	{
		$r_type = 'git';
		($r_host, $r_port, $r_path) = ($1, $2, $3);
	}

	# SCP style URL
	elsif ( $r_url =~ /^
		(\w+@)?				# 1 user@
		([a-zA-Z0-9-.]+)	# 2 host
		:					# :
		(.+)?				# 3 path
		/x
	)
	{
		$r_type = 'ssh';
		($r_user, $r_host, $r_path) = ($1, $2, $3);
	}

	# SSH style URL
	elsif ( $r_url =~ /^
		ssh:\/\/
		(\w+@)?				# 1 user@
		([a-zA-Z0-9-.]+)	# 2 host
		(:[0-9]+)?			# 3 :port
		(.+)?				# 4 path
		/x
	)
	{
		$r_type = 'ssh';
		($r_user, $r_host, $r_port, $r_path) = ($1, $2, $3, $4);
	}

	my $r_data = {
		r_name => $r_name,
		r_url => $r_url,
		r_dir => $r_dir,
		r_user => $r_user,
		r_host => $r_host,
		r_port => $r_port,
		r_path => $r_path,
		r_type => $r_type,
	};

	GROUP: for my $g_name ( keys %{$config->{'Group'}} )
	{
		my $g_data = $config->{'Group'}->{$g_name};

		# Test Match conditions
		next GROUP if (
			@{$g_data->{'Match_LocalHost'}} &&
			! grep { hostname =~ $_; } @{$g_data->{'Match_LocalHost'}}
		);

		next GROUP if (
			! defined($r_host) ||
			@{$g_data->{'Match_RemoteHost'}} &&
			! grep { $r_host =~ $_ } @{$g_data->{'Match_RemoteHost'}}
		);

		# Find matching Path set
		for my $p_name ( keys %{$g_data->{'Path'}} )
		{
			my $p_data = $g_data->{'Path'}->{$p_name};
			my $p_path;

			if ( $r_type eq 'ssh' )
			{
				for $p_path ( @{$p_data->{'SSHPath'}->{'all'}} )
				{
					if ( $r_path =~ /^$p_path/ )
					{
						$retval = _enforce_patterns($opt, $repo, $buffer, $g_data, $r_data, $p_data, $p_path);
					}
				}
			}

			if ( $r_type eq 'git' )
			{
				for $p_path ( @{$p_data->{'GitPath'}->{'all'}} )
				{
					if ( $r_path =~ /^$p_path/ )
					{
						$retval = _enforce_patterns($opt, $repo, $buffer, $g_data, $r_data, $p_data, $p_path);
					}
				}
			}
		}
	}
	return $retval;
}


sub _enforce_patterns
{
	my ($opt, $repo, $buffer, $g_data, $r_data, $p_data, $p_path) = @_;
	my $retval;
	my $rv;
	my @msgs;
	my @patterns = @{$g_data->{'Pattern'}};

	# force_separate_pushurl
	$rv = undef;
	@msgs=();
	($rv, @msgs) = _pattern_force_separate_pushurl($opt, $repo, $g_data, $r_data, $p_data, $p_path) if (
		$r_data->{'r_dir'} eq 'fetch'
	);
	$retval = defined($retval) ? $retval && $rv : $rv if defined($rv);
	push @$buffer, @msgs;

	# use_host
	$rv = undef;
	@msgs=();
	($rv, @msgs) = _pattern_use_host($opt, $repo, $g_data, $r_data, $p_data, $p_path) if (
		( grep { $_ eq 'use_host' } @patterns )
	);
	$retval = defined($retval) ? $retval && $rv : $rv if defined($rv);
	push @$buffer, @msgs;

	# pull_git
	$rv = undef;
	@msgs=();
	($rv, @msgs) = _pattern_pull_git($opt, $repo, $g_data, $r_data, $p_data, $p_path) if (
		( grep { $_ eq 'pull_git' } @patterns ) &&
		$r_data->{'r_dir'} eq 'fetch' &&
		$r_data->{'r_type'} ne 'git' &&
		! defined($r_data->{'r_port'})
	);
	$retval = defined($retval) ? $retval && $rv : $rv if defined($rv);
	push @$buffer, @msgs;

	# push_ssh
	$rv = undef;
	@msgs=();
	($rv, @msgs) = _pattern_push_ssh($opt, $repo, $g_data, $r_data, $p_data, $p_path) if (
		( grep { $_ eq 'push_ssh' } @patterns ) &&
		$r_data->{'r_dir'} eq 'push' &&
		$r_data->{'r_type'} ne 'ssh'
	);
	$retval = defined($retval) ? $retval && $rv : $rv if defined($rv);
	push @$buffer, @msgs;

	# use_first_ssh_path
	$rv = undef;
	@msgs=();
	($rv, @msgs) = _pattern_use_first_ssh_path($opt, $repo, $g_data, $r_data, $p_data, $p_path) if (
		( grep { $_ eq 'use_first_ssh_path' } @patterns ) &&
		$r_data->{'r_type'} eq 'ssh' &&
		$p_path ne $p_data->{'SSHPath'}->{'preferred'}
	);
	$retval = defined($retval) ? $retval && $rv : $rv if defined($rv);
	push @$buffer, @msgs;

	return $retval
}

sub _pattern_force_separate_pushurl
{
	my ($opt, $repo, $g_data, $r_data, $p_data, $p_path) = @_;

	# If using git remote set-url --push, git will write a new 'pushurl' to
	# .git/config.  If not using --push the docs say it will affect the first
	# remote.  What they don't mention is that this really means BOTH remotes,
	# since internally fetch and push are both using the remote.foo.url config.

	my $pushurl;

	try {
		$pushurl = $repo->command_oneline(
			'config',
			'--get',
			'remote.' . $r_data->{'r_name'} . '.pushurl',
		);
	} catch Git::Error::Command with { };

	return undef if defined($pushurl);

	# Duplicate (fetch) URL to push URL so it does not overwrite both
	my @cmd = (
		'config',
		'remote.' . $r_data->{'r_name'} . '.pushurl',
		$r_data->{'r_url'}
	);

	if ( $opt->{'noop'} )
	{
		return 1, "Would run: git @cmd";
	}
	else
	{
		$repo->command_noisy(@cmd);
		return 1, "Updating " . $r_data->{'r_name'} . " to use distinct pushurl config";
	}
}

sub _pattern_use_host
{
	my ($opt, $repo, $g_data, $r_data, $p_data, $p_path) = @_;

	my $newhost = $g_data->{'Pattern_Args'}->{'use_host'};
	my $oldhost = $r_data->{'r_host'};
	my $confkey = 'remote.' . $r_data->{'r_name'} . ($r_data->{'r_dir'} eq 'push' ? '.pushurl' : '.url');
	my $url;

	try {
		$url = $repo->command_oneline( 'config', '--get', $confkey);
	} catch Git::Error::Command with { };

	return undef unless defined($url);
	return undef if $newhost eq $oldhost;
	return undef unless $url =~ s/$oldhost/$newhost/;

	my @cmd = (
		'config',
		$confkey,
		$url
	);

	$r_data->{'r_host'} = $newhost;

	if ( $opt->{'noop'} )
	{
		return 1, "Would run: git @cmd";
	}
	else
	{
		$repo->command_noisy(@cmd);
		return 1, "Updating " . $r_data->{'r_name'} . " to use hostname $newhost";
	}
}

sub _pattern_pull_git
{
	my ($opt, $repo, $g_data, $r_data, $p_data, $p_path) = @_;

	my $newpath = $p_data->{'GitPath'}->{'preferred'} . substr( $r_data->{'r_path'}, length($p_path) );

	if ( $r_data->{'r_type'} ne 'ssh' )
	{
		return 0, "Don't know how to convert to git:// from " . $r_data->{'r_type'};
	}

	my @cmd = (
		'remote',
		'set-url',
		$r_data->{'r_name'},
		(
			sprintf "git://%s%s",
				$r_data->{'r_host'},
				$newpath
		)
	);

	$r_data->{'r_type'} = 'git';
	$r_data->{'r_path'} = $newpath;

	if ( $opt->{'noop'} )
	{
		return 1, "Would run: git @cmd";
	}
	else
	{
		$repo->command_noisy(@cmd);
		return 1, "Updating " . $r_data->{'r_name'} . " to pull using Git protocol";
	}
}

sub _pattern_push_ssh
{
	my ($opt, $repo, $g_data, $r_data, $p_data, $p_path) = @_;

	my $newpath = $p_data->{'SSHPath'}->{'preferred'} . substr( $r_data->{'r_path'}, length($p_path) );

	if ( $r_data->{'r_type'} ne 'git' )
	{
		return 0, ("Don't know how to convert to ssh: from " . $r_data->{'r_type'} );
	}

	my @cmd = (
		'remote',
		'set-url',
		'--push',
		$r_data->{'r_name'},
		(
			sprintf "%s:%s",
				$r_data->{'r_host'},
				$newpath
		)
	);

	$r_data->{'r_type'} = 'ssh';
	$r_data->{'r_path'} = $newpath;

	if ( $opt->{'noop'} )
	{
		return 1, "Would run: git @cmd";
	}
	else
	{
		$repo->command_noisy(@cmd);
		return 1, "Updating " . $r_data->{'r_name'} . " to push using SSH protocol";
	}
}

sub _pattern_use_first_ssh_path
{
	my ($opt, $repo, $g_data, $r_data, $p_data, $p_path) = @_;

	my $newpath = $p_data->{'SSHPath'}->{'preferred'} . substr( $r_data->{'r_path'}, length($p_path) );

	my @cmd = ( 'remote', 'set-url' );
	push @cmd, '--push' if $r_data->{'r_dir'} eq 'push';
	push @cmd,
		$r_data->{'r_name'},
		(
			sprintf "%s:%s",
				$r_data->{'r_host'},
				$newpath,
		);

	$r_data->{'r_path'} = $newpath;

	if ( $opt->{'noop'} )
	{
		return 1, "Would run: git @cmd";
	}
	else
	{
		$repo->command_noisy(@cmd);
		return 1, "Updating " . $r_data->{'r_name'} . " to use preferred SSH path";
	}
}

=back

=head1 AUTHOR

Tom Embt

=head1 COPYRIGHT

Copyright 2010 Synacor, Inc.

=cut

1; # End of Git::FixRemotes
