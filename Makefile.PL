use ExtUtils::MakeMaker;

my %prereq = ();
my @libs = ('linux');

if ($^O =~ /win32/i) {
    $prepreq{'Win32::API'} = 0;
    @libs = ('win32');
} elsif ($^O =~ /linux/i) {
    # NOTHING TO DO
} else {
    warn "Your operating system is not supported";
}

WriteMakefile(
    NAME            => 'Audio::Beep',
    VERSION_FROM    => 'Beep.pm', 
    PREREQ_PM       => \%prereq,
    PMLIBDIRS       => \@libs,
    ($] >= 5.005 
        ? (
            ABSTRACT_FROM   => 'Beep.pm', 
            AUTHOR          => 'Giulio Motta <GIULIENK@cpan.org>'
        ) : ()
    ),
);
