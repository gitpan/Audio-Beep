use ExtUtils::MakeMaker;

my %prereq = ();
my @libs = ();

if ($^O eq 'MSWin32') {
    warn "Currently the only Windows systems supported are NT, 2000 and XP"
        unless Win32::GetOSVersion() == 2;
    $prepreq{'Win32::API'} = 0;
    @libs = ('lib/Audio/Beep/Win32/');
} elsif ($^O eq 'linux') {
    @libs = ('lib/Audio/Beep/Linux/');
} else {
    warn "Your operating system is not supported: 
          i will install just the Audio::Beep module (no submodules)";
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
        ) 
        : ()
    ),
);

