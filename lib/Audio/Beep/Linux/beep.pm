package Audio::Beep::Linux::beep;

$Audio::Beep::Linux::beep::VERSION = 0.04;

use strict;

sub new {
    my $class = shift;
    my %hash = @_;
    $hash{path} ||= _search_path();
    return unless $hash{path};
    return bless \%hash, $class;
}

sub play {
    my $self = shift;
    my ($pitch, $duration) = @_;
    return `$self->{path} -l $duration -f $pitch`;
}

sub rest {
    my $self = shift;
    my ($duration) = @_;
    select undef, undef, undef, $duration/1000;
    return 1;
}

sub _search_path {
    my @PROB_PATHS = qw(
        /usr/bin/beep
        /usr/local/bin/beep
        /bin/beep
    );
    for (@PROB_PATHS) {
        return $_ if -e and -x _;
    }
    return;
}

=head1 NAME

Audio::Beep::Linux::beep - Audio::Beep player module using the "beep" program

=head1 SYNOPIS

    my $player = Audio::Beep::Linux::beep->new([%options]);

=head1 USAGE

The new class method can receive as option in hash fashion the following
directives

=over 4

=item path => '/full/path/to/beep'

With the path option you can give your full path to the "beep" program to
the object. If you don't use this option the new method will look anyway
in some likely places where "beep" should be before returning undef.

=back

=head1 NOTES

The "beep" program is a Linux program wrote by Johnathan Nightingale.
You should find C sources in the tarball where you found this file.
The "beep" program needs to be (usually) executed as root to actually work.
Please check "beep" man page for more info.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright 2003 Giulio Motta <giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
