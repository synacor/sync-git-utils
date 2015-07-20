requires 'App::Cmd';
requires 'File::Spec';
requires 'Config::INI';
requires 'Config::General';
requires 'Git';
requires 'LWP::Simple';
requires 'Term::ANSIColor';
requires 'IPC::Run';
requires 'String::ShellQuote';

on 'test' => sub {
	requires 'Test::More';
}
