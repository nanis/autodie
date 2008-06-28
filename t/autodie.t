#!/usr/bin/perl -w
use strict;

use constant NO_SUCH_FILE => 'this_file_had_so_better_not_be_here';
use constant PERL58 => ($] < 5.010);

use Test::More tests => 18;

{

    use autodie qw(open);

    eval { open(my $fh, '<', NO_SUCH_FILE); };
    like($@,qr{Can't open},"autodie qw(open) in lexical scope");

    no autodie qw(open);

    eval { open(my $fh, '<', NO_SUCH_FILE); };
    is($@,"","no autodie qw(open) in lexical scope");

    use autodie qw(open);
    eval { open(my $fh, '<', NO_SUCH_FILE); };
    like($@,qr{Can't open},"autodie qw(open) in lexical scope 2");

    no autodie; # Should turn off all autodying subs
    eval { open(my $fh, '<', NO_SUCH_FILE); };
    is($@,"","no autodie in lexical scope 2");

    # Turn our pragma on one last time, so we can verify that
    # falling out of this block reverts it back to previous
    # behaviour.
    use autodie qw(open);
    eval { open(my $fh, '<', NO_SUCH_FILE); };
    like($@,qr{Can't open},"autodie qw(open) in lexical scope 3");

}

eval { open(my $fh, '<', NO_SUCH_FILE); };
is($@,"","autodie open outside of lexical scope");

# eval { autodie->import(); };
# ok(! $@, "Bare autodie allowed");   # TODO: Test it turns on ':all'

ok(1, "Import test disabled");

{
    use autodie qw(:io);

    eval { open(my $fh, '<', NO_SUCH_FILE); };
    like($@,qr{Can't open},"autodie q(:io) makes autodying open");

    no autodie qw(:io);

    eval { open(my $fh, '<', NO_SUCH_FILE); };
    is($@,"", "no autodie qw(:io) disabled autodying open");
}

{
    package Testing_autodie;

    use Test::More;

    use constant NO_SUCH_FILE => ::NO_SUCH_FILE();

    use Fatal qw(open);

    eval { open(my $fh, '<', NO_SUCH_FILE); };

    like($@, qr{Can't open}, "Package fatal working");
    is(ref $@,"","Old Fatal throws strings");

    {
        use autodie qw(open);

        ok(1,"use autodie allowed with Fatal");

        eval { open(my $fh, '<', NO_SUCH_FILE); };
        like($@, qr{Can't open}, "autodie and Fatal works");
        isa_ok($@, "autodie::exception"); # autodie throws real exceptions

    }

    eval { open(my $fh, '<', NO_SUCH_FILE); };

    like($@, qr{Can't open}, "Package fatal working after autodie");
    is(ref $@,"","Old Fatal throws strings after autodie");

    eval " no autodie qw(open); ";

    ok($@,"no autodie on Fataled sub an error.");

    TODO: {
        local $TODO = "Broken under the One True Way (for now)";

        eval "
            no autodie qw(close);
            use Fatal 'close';
        ";

        ok($@, "Using fatal after autodie is an error.");
    }
}

