use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Audio::Beep',
    'VERSION_FROM'  => 'Beep.pm',       # finds $VERSION
    'PREREQ_PM'     => {},              # e.g., Module::Name => 1.1
    ($] >= 5.005 
        ? (
            ABSTRACT_FROM   => 'Beep.pm',   # retrieve abstract from module
            AUTHOR          => 'Giulio Motta <GIULIENK@cpan.org>'
        ) : ()
    ),
);
