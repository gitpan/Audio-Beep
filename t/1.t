use Test::More tests => 3;

BEGIN { use_ok('Audio::Beep') };

my $beeper;

ok(defined($beeper = Audio::Beep->new()));

ok(defined $beeper->player);

