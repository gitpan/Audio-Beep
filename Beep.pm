package Audio::Beep;

$Audio::Beep::VERSION = 0.06;

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
    $hash{player} ||=  _best_player();
    carp "No player found. You should specify one before playing anything." 
        unless $hash{player};
    return bless \%hash, $class;
}

sub player {
    my $self = shift;
    my ($player) = @_;
    $self->{player} = $player if $player;
    return $self->{player};
}

sub rest {
    my $self = shift;
    my ($rest) = @_;
    $self->{rest} = $rest if defined $rest;
    return $self->{rest};
}

sub play {
    my $self = shift;
    my ($music) = @_;
    
    my %p = (
        note        =>  'c',
        duration    =>  4,
        octave      =>  0,
        bpm         =>  120,
        pitch_mod   =>  0,
        dot         =>  0,
        relative    =>  1,
        transpose   =>  0,
    );
    
    while ($music =~ /\G(?:([^\s#]+)\s*|#[^\n]*\n|\s*)/g) { 
        local $_ = $1 or next;
        
        if ( /^\\(.+)/ ) {
            COMMAND: {
                local $_ = $1;
                /^(?:bpm|tempo)(\d+)/   and do {$p{bpm} = $1; last};
                /^rel/                  and do {$p{relative} = 1; last};
                /^norel/                and do {$p{relative} = 0; last};
                /^transpose([',]+)/     and do {
                    local $_ = $1;
                    $p{transpose} = tr/'/'/ - tr/,/,/;
                    last;
                };
                carp qq|Command "$_" is unparsable\n| if $^W;
            }
            next;
        }
        
        my ($note, $mod, $octave, $dur, $dot) = 
            /^\W*([cdefgabr])(is|es|s)?([',]+)?(\d+)?(\.+)?\W*$/;
        
        unless ($note) {
            carp qq|Note "$_" is unparsable\n| if $^W;
            next;
        }
        
        $p{duration} = $dur if $dur;

        $p{dot} = 0;
        do{ $p{dot} += tr/././ for $dot } if $dot;
        
        if ( $note eq 'r' ) {
            $self->player->rest( _duration(\%p) );
        } else {
            if ( $p{relative} ) {
                my $diff = $NOTES{ $p{note} } - $NOTES{ $note };
                $p{octave} += $diff < 0 ? -1 : 1 if abs $diff > 5;
            } else {
                $p{octave} = $p{transpose};
            }
        
            do{ $p{octave} += tr/'/'/ - tr/,/,/ for $octave } if $octave;
        
            $p{pitch_mod} = 0;
            $p{pitch_mod} = $mod eq 'is' ? 1 : -1 if $mod;
        
            $p{note} = $note;
            $self->player->play( _pitch(\%p), _duration(\%p) );
        }
        
        select undef, undef, undef, $self->rest / 1000 if $self->rest;
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
    my %os_modules = (
        linux   =>  [
            'Audio::Beep::Linux::beep',
            'Audio::Beep::Linux::PP'
        ],
        win32   =>  [
            'Audio::Beep::Win32::API'
        ]
    );
    
    no strict 'refs';
    
    for my $os (keys %os_modules) {
        for my $mod ( @{ $os_modules{$os} } ) {
            if ($^O =~ /$os/i and eval "require $mod") {
                my $player = $mod->new();
                return $player if defined $player;
            }
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

=head1 SYNOPSIS

    #functional simple way
    use Audio::Beep;

    beep($freq, $milliseconds);

    #OO more musical way
    use Audio::Beep;

    my $beeper = Audio::Beep->new();
    
                # lilypond subset syntax accepted
                # relative notation is the default 
                # (now correctly implemented)
    my $music = "g' f bes' c8 f d4 c8 f d4 bes c g f2";
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

=back

=over 8

=item player => [player object]

You can initialize your player object and then give it to the 
Audio::Beep object. 
Player objects come from Audio::Beep submodules (like Audio::Beep::Linux::beep).
The new method will try to look up the best player on your platform.
Still passing the player to the new method is safer (and you can sometimes
personalize the player itself).

=item rest => [ms]

Sets the rest in milliseconds between every sound played (and
even pause). This is useful for users which computer beeper has problems
and would just stick to the first sound played.
For example on my PowerbookG3 i have to set this around 120 milliseconds.
In that way i can still hear some music. Otherwise is just a long single beep.

=back

=over 4

=item $beeper->play( $music )

Plays the "music" written in $music.
The accepted format is a subset of lilypond.org syntax.
The string is a space separated list of notes to play.
See the NOTATION section below for more info.

=item $beeper->player( [player] )

Sets the player object that will be used to play your music.
With no parameter it just gives you back the current player.

=item $beeper->rest( [ms] )

Sets the extra rest between each note. 
See the rest option above at the C<new> method for more info.
With no parameter it gives you back the current rest.

=back

=head1 NOTATION

The defaults at start are middle octave C and a quarter length.
Standard notation is the relative notation. 
Here is an explanation from Lilypond documentation:

    If no octave changing marks are used, the basic interval between 
    this and the last note is always taken to be a fourth or less 
    (This distance is determined without regarding alterations; 
    a fisis following a ceses will be put above the ceses)

    The octave changing marks ' and , can be added to raise or lower 
    the pitch by an extra octave.

You can switch from relative to non relative notation (in which you specify for
every note the octave) using the C<\norel> and C<\rel> commands (see below)

=head2 Notes

Every note has the following structure:
    
    [note][flat|sharp][octave][duration][dots]

NB: previous note duration is used if omitted.
"Flatness", "Sharpness" and "Dottiness" are reset after each note. 

=over 4

=item note

A note can be any of [c d e f g a b] or [r] for rest.

=item flat or sharp

A sharp note is produced postponing a "is" to the note itself 
(like "cis" for a C#).
A flat note is produced adding a "es" or "s" 
(so "aes" and "as" are both an A flat).

=item octave

A ' (apostrophe) raise one octave, while a , (comma) lower it.

=item duration

A duration is expressed with a number. 
A 4 is a beat, a 1 is a whole 4/4 measure. Higher the number, shorter the note.

=item dots

You can add dots after the duration number to add half its length. 
So a4. is an A note long 1/4 + 1/8 and gis2.. is a G# long 7/8 (1/2 + 1/4 + 1/8)

=item special note: "r"

A r note means a rest. You can still use duration and dots parameters. 

=back

=head2 Special Commands

Special commands always begin with a "\". They change the behavior of the
parser or the music played. Unlike in the Lilypond original syntax, these
commands are embedded between notes so they have a slightly different syntax.

=over 4

=item \bpm(\d+)

You can use this option  to change the tempo of the music.
The only parameter you can use is a number following the bpm string 
(like "bpm144").  
BPM stands for Beats Per Minute.
The default is 120 BPM.
You can also invoke this command as C<\tempo>

=item \norel

Switches the relative mode off. From here afterward you have to always specify
the octave where the note is.

=item \rel

Switches the relative mode on. This is the default.

=item \transpose([',]+)

You can transpose all your music up or down some octave. 
' (apostrophe) raise octave. , (comma) lowers it. This has effect just
if you are in non-relative mode.

=back

=head2 Comments

You can embed comments in your music the Perl way. Everything after a #
will be ignored

=head2 Music Examples

    my $scale = <<EOS;
    \rel \bpm144
    c d e f g a b c2. r4    # a scale going up
    c b a g f e d c1        # and then down
    EOS

    my $music = <<EOM; # a Smashing Pumpkins tune
    \bpm90 \norel \transpose''
        d8 a, e a, d a, fis16 d a,8
        d  a, e a, d a, fis16 d a,8
    EOM

There should be extra examples in the "music" directory of this tarball.

=head1 EXAMPLES

                  #a louder beep
 perl -MAudio::Beep -ne 'print and beep(550, 1000) if /ERROR/i' logfile


=head1 REQUIREMENTS

=head2 Linux

Requires either the "beep" program by Johnathan Nightingale 
(you should find sources in this tarball) SUID root or you to be root (that's
because we need writing access to the /dev/console device).
If you don't have the "beep" program this library will also assume some kernel
constants which may vary from kernel to kernel (or not, i'm no kernel expert).
Anyway this was tested on a 2.4.20 kernel compiled for i386.
With the same kernel i have problems on my PowerBook G3 (it plays a continous
single beep). See the C<rest> method if you'd like to play something anyway.

=head2 Windows

Requires Windows NT, 2000 or XP and the Win32::API module. 
You can find sources on CPAN. 
Some PPM precompiled packages are at http://dada.perl.it/PPM/
No support is available for Windows 95, 98 and ME yet:
that would require some assembler and an XS module.

=head1 BACKEND

If you are a developer interested in having Audio::Beep working on your
platform, you should think about writing a backend module.
A backend module for Beep should offer just a couple of methods:

NB: FREQUENCY is in Hertz. DURATION in milliseconds

=over 4

=item new([%options])

This is kinda obvious. Take in the options you like. Keep the hash fashion
for parameters, thanks.

=item play(FREQUENCY, DURATION)

Plays a single sound.

=item rest(DURATION)

Rests a DURATION amount of time

=back

=head1 TODO

This module works for me, but if someone wants to help here is some cool stuff to do:

- an XS backend

- an XS Windoze backend (look at the Prima project for some useful code)

=head1 BUGS

Some of course.

=head1 COPYRIGHT

Copyright 2003 Giulio Motta <giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
