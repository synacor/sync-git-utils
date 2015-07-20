use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME    => 'Synacor-Git-Utilities',
    AUTHOR  => q{Synacor, Inc.},
    VERSION => '1.3.3',

    ABSTRACT => 'Tools for working with Git',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'gpl_3') : ()),
    PL_FILES  => {},
    EXE_FILES => [
                  'bin/git-gank',
                  'bin/bulk-changed-files',
                  'bin/git-pgd',
                  'bin/git-ship',
                  'bin/git-foreach',
                  'bin/git-bulk',
                  'bin/git-collab',
                  'bin/git-mk-pub-repo',
                  'bin/git-fix-remotes',
                 ],
    PREREQ_PM => {
		'Test::More' => 0,
		'App::Cmd' => 0,
		'File::Spec' => 0,
		'Config::INI' => 0,
		'Config::General' => 0,
		'Git' => 0,
		'LWP::Simple' => 0,
		'Term::ANSIColor' => 0,
		'IPC::Run' => 0,
		'String::ShellQuote' => 0,
	},
    dist      => {COMPRESS     => 'gzip -9f', SUFFIX => 'gz',},
    clean     => {FILES        => 'sync_git_utils-*, *.spec'},
             );
