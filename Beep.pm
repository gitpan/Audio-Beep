package Audio::Beep;

$Audio::Beep::VERSION = 0.02;

use strict;
use Carp;
use Exporter;
use vars qw(%NOTES @PITCH @EXPORT @EXPORT_OK @ISA);
@ISA        = qw(Exporter);
@EXPORT     = qw(beep);
@EXPORT_OK  = qw(beep);

%NOTES = (
    c   =>  0,
    d   =>  2,
    e   =>  4,
    f   =>  5,
    g   =>  7,
    a   =>  9,
    b   =>  11,
);

@PITCH = (
    261.6, 277.2, 
    293.6, 311.1, 
    329.6, 
    349.2, 370.0, 
    392.0, 415.3, 
    440.0, 466.1,
    493.8,
);

sub new {
    my $class = shift;
    my (%hash) = @_;
    $hash{player} ||= _best_player();
    carp "No player found for this platform. 
          You should specify one before paying anything." unless $hash{player};
    return bless \%hash, $class;
}

sub player {
    my $self = shift;
    my ($player) = @_;
    $self->{player} = $player if $player;
    return $self->{player};
}

sub play {
    my $self = shift;
    my ($music) = @_;
    my %p = (
        duration    =>  4,
        octave      =>  0,
        bpm         =>  120,
        pitch_mod   =>  0,
        dot         =>  0,
    );
    for (split /\s+/, $music) {
        $p{bpm} = $1 and next if (/^bpm(\d+)/);
        
        my ($note, $mod, $octave, $dur, $dot) = 
            /^([cdefgabr])(is|es|s)?([',]+)?(\d+)?(\.+)?/;
        
        unless ($note) {
            print STDERR qq|Atom "$_" is unparsable\n| if $^W;
            next;
        }
        
        $p{note} = $note;
        
        $p{pitch_mod} = 0;
        $p{pitch_mod} = 1  if $mod eq 'is';
        $p{pitch_mod} = -1 if $mod eq 'es' or $mod eq 's';
        
        $p{octave} += tr/'/'/ - tr/,/,/ for $octave;

        $p{duration} = $dur if $dur;

        $p{dot} = 0;
        $p{dot} += tr/././ for $dot;
        
        if ($p{note} eq 'r') {
            $self->player->rest( _duration(\%p) );
        } else {
            $self->player->play( _pitch(\%p), _duration(\%p) );
        }
    }
}

sub _pitch {
    my $p = shift;
    return $PITCH[($NOTES{ $p->{note} } + $p->{pitch_mod}) % 12] * 
            (2 ** $p->{octave});
}

sub _duration {
    my $p = shift;
    my $dur = 4 / $p->{duration};
    if ( $p->{dot} ) {
        my $half = $dur / 2;
        for (my $i = $p->{dot}; $i--; ) {
            $dur  += $half;
            $half /= 2;
        }
    }
    return int( $dur * (60 / $p->{bpm}) * 1000 );
}

sub _best_player {
    my $player;
    if ($^O =~ /linux/i) {
        if ( eval { require Audio::Beep::Linux::beep } ) {
            $player = Audio::Beep::Linux::beep->new();
            return $player if defined $player;
        }
        if ( eval { require Audio::Beep::Linux::PP } ) {
            $player = Audio::Beep::Linux::PP->new();
            return $player if defined $player;
        }
    }
    return;
}


sub beep {
    my ($pitch, $duration) = @_;
    $pitch      ||= 440;
    $duration   ||= 100;
    _best_player()->play($pitch, $duration);
}


=head1 NAME

Audio::Beep - a module to use your computer beeper in fancy ways

=head1 IMPORTANT!!!

This module will work just with the GNU/Linux operating system!
It requires either the "beep" program by Johnathan Nightingale 
(you should find sources in this tarball) SUID root or you to be root (that's
because we need writing access to the /dev/console device).
If you don't have the "beep" program this library will also assume some kernel
constants which may vary from kernel to kernel (or not, i'm no kernel expert).
Anyway this was tested on a 2.4.20 kernel compiled for i386. 
With the same kernel i have problems on my PowerBook G3.

=head1 SYNOPSIS

    #functional simple way
    use Beep;

    beep($freq, $milliseconds);

    #OO more musical way
    use Beep;

    my $beeper = Beep->new();
    
                #lilypond subset syntax accepted
    my $music = "g f bes c'8 f d4 c8 f d4 bes, c' g, f2";
                # Pictures at an Exhibition by Modest Mussorgsky

    $beeper->play( $music );

=head1 USAGE

=head2 Exported Functions

=over 4

=item beep([FREQUENCY], [DURATION]);

 Plays a customizable beep out of your computer beeper.
 FREQUENCY is in Hz. Defaults to 440.
 DURATION is in milliseconds. Defaults to 100.

=back

=head2 OO Methods

=over 4

=item Audio::Beep->new([%options])

Returns a new "beeper" object. 
Follows the available options for the new method to be passed in hash fashion.

=over 4

=item player => [player object]

You can initialize your player object and then give it to the 
Audio::Beep object. 
Player objects come from Audio::Beep submodules (like Audio::Beep::Linux::beep).
The new method will try to look up the best player on your platform.
Still passing the player to the new method is safer (and you can sometimes
personalize the player itself).

=back


=item $beeper->play( $music )

Plays the "music" written in $music. 
The accepted format is a subset of lilypond.org syntax. 
The string is a space separated list of notes to play.
Every note has the following structure:
    
    [note][flat|sharp][octave][duration][dots]

NB: if some part is missing the settings from the previous note are applied for octave and duration. 
"Flatness", "Sharpness" and "Dottiness" are reset after each note. 
The defaults at start are middle octave and a quarter length.

=over 4

=item note

A note can be any of [c d e f g a b] or [r] for rest.

=item flat or sharp

A sharp note is produced postponing a "is" to the note itself 
(like "cis" for a C#).
A flat note is produced adding a "es" or "s" 
(so "aes" and "as" are both an A flat).

=item octave

The octave setting is always relative to the previous one. 
A ' (apostrophe) raise one octave, while a , (comma) lower it.

=item duration

A duration is expressed with a number. 
A 4 is a beat, a 1 is a whole 4/4 measure. Higher the number, shorter the note.

=item dots

You can add dots after the duration number to add half its length. 
So a4. is an A note long 1/4 + 1/8 and gis2.. is a G# long 7/8 (1/2 + 1/4 + 1/8)

=item special note: "r"

A r note means a rest. You can still use duration and dots parameters. 
Flat and sharp will be ignored. Octave will work, changing the octave.

=item spacial note: "bpm"

You can use a bpm (beats per minute) "note" to change the tempo of the music. 
The only parameter you can use is a number following the bpm string (like "bpm144"). 
The default is 120 BPM.

=back

=head2 Music Examples

    my $music = <<EOM; # a Smashing Pumpkins tune
    bpm90   d''8 a, e' a, d' a, fis'16 d a,8
            d'   a, e' a, d' a, fis'16 d a,8
    EOM

    my $music = <<EOM; # some Bach
        r'8 c16 b c8 g as     c16 b c8 d
        g,  c16 b c8 d f,16 g as4      g16 f
        es4
    EOM

=back

=item $beeper->player( [player] )

Sets the player object that will be used to play your music.
With no parameter it just give you back the current player.

=head1 EXAMPLES

                  #a louder beep
 perl -MBeep -ne 'print and beep(550, 1000) if /ERROR/' somelogfile

=head1 BACKEND

A backend module for Beep should offer just a couple of methods:
 NB: FREQUENCY is in Hertz. DURATION in milliseconds
 
=over 4

=item play(FREQUENCY, DURATION)

Plays a single sound.

=item rest(DURATION)

Rests a DURATION amount of time

=back

=head1 TODO

This module works for me, but if someone wants to help here is some cool stuff to do:

    - an XS backend
    - an XS Windoze backend (and other OSs)
    - a parse method to preparse the input (usefull??)
    - with a cool backend we could export a tied filehandle 
      to which it would be possible to write directly from Perl

=head1 BUGS

 Sure to be plenty.
 Produces a ton of crap if warnings are turned on.

=head1 COPYRIGHT

Copyright 2003 Giulio Motta <giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
