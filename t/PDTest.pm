package PDTest;


use warnings;
use strict;


use Cwd qw(abs_path);
use Env qw(GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_DATE GIT_AUTHOR_DATE PERL5LIB PATH);
use File::Temp qw(tempdir);
use IPC::Open2;

my $start_dir;
my $path            = Cwd::abs_path("bin");
my $command;
my $output_location = 'output';
my $temp_dir_parent = '/var/tmp/';
my $temp_dir;

# Sets the given command and creates and moves to the trash directory 
sub setup
{
    my $cmd = shift;
    set_command($cmd) if $cmd;

    $start_dir = Cwd::cwd();
    $temp_dir = tempdir(CLEANUP => 1, DIR => $temp_dir_parent);
    $output_location = "$temp_dir/$output_location";
    chdir($temp_dir);

    $GIT_AUTHOR_EMAIL    = 'author@example.com';
    $GIT_AUTHOR_NAME     = 'A U Thor';
    $GIT_COMMITTER_EMAIL = 'committer@example.com';
    $GIT_COMMITTER_NAME  = 'C O Mitter';

    my $perllib = $PERL5LIB;
    $PERL5LIB = "$start_dir/lib";
    if ($perllib) {
            $PERL5LIB .= ':' . $perllib;
    }

    my $binpath = $PATH;
    $PATH = $path;
    if ($binpath) {
            $PATH .= ':' . $binpath;
    }

    return 1;
}


# Changes directory to the starting directory and removes the trash directory
sub teardown
{
    my $err = shift;
    $err = 0 unless defined $err;
    if ($start_dir){
        chdir($start_dir);
    }
    exit($err);
}


# Sets the given command and ensures it exists
sub set_command
{
    $command  = shift;
    die ("Could not find command: $path/$command\n") unless (-f $path . '/' . $command);
    return 1;
}


# Runs the command with given arguments
# Redirects STDERR to STDIN
sub run
{
    return `$path/$command @_ 2>&1` if $command;
}


# Runs the command with the given arguments
# Returns handles to the command's STDIN
# Output is redirected to the output file
sub run_pipe
{
    return unless $command;
    clear_output();
    open (my $PIPE, '|-', "$path/$command @_ > $output_location 2>&1");
    return $PIPE;
}


# Returns all of the output in the output file as a string
sub get_output
{
    local $/;
    open (my $OUT, '<', $output_location);
    my $output = <$OUT>;
    close ($OUT);
    return $output;
}


# Removes the output file
sub clear_output
{
    unlink($output_location) if (-f $output_location);
    return 1;
}


# Runs git demo --basic and ignores ALL output
sub set_up_repos
{
    return `$path/git-demo --basic --directory=demo > /dev/null 2>&1`;
}


# Generates a given number of commits on the current git repo
sub generate_commits
{
    my $num = shift;
    return `$path/git-demo -m $num > /dev/null 2>&1`;
}


# Prepares git to make a commit at the specified unix timestamp
sub commit_time
{
    my $time = shift;
    $GIT_COMMITTER_DATE = "$time -0700";
    $GIT_AUTHOR_DATE    = "$time -0700";
    return 1;
}


# Teardown the testing environment if something dies
BEGIN {
#    $SIG{__DIE__} = sub { print "@_\n"; teardown(1); };
    $SIG{INT}     = sub { teardown(1); };
}

END {
    teardown();
}


1;
