#!/usr/bin/perl

# http://use.perl.org/~Ovid/journal/37797

use strict;
use warnings;

use Test::More;

BEGIN {
    for ( keys %INC ) {
        plan skip_all => 'Running coverage tests' if ($_ eq 'Devel/Cover.pm');
    }
}

use File::Find;
use File::Spec;

use lib 'lib';

BEGIN {
    my $DIR = 'lib/';

    sub to_module {
        my $file = shift;
        $file =~ s{\.pm$}{};
        $file =~ s{\\}{/}g;    # to make win32 happy
        $file =~ s/^$DIR//;
        return join '::' => grep _ => File::Spec->splitdir($file);
    }

    my @modules = qw(   
                        Date::Manip
                        Git
                        HTML::Tree
                        IPC::Run
                        JSON
                        LWP::Simple
                        LWP::UserAgent
                        String::ShellQuote
                        Sub::Install
                    );

    find({
            no_chdir => 1,
            wanted   => sub {
            push @modules => map { to_module $_ } $File::Find::name
                if /\.pm$/;
            },
        },
        $DIR
    );

    plan tests => scalar @modules;

    for my $module (@modules) {
        use_ok $module or BAIL_OUT("Could not use $module");
    }
}
