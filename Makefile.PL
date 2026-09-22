use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Physics::Electrodeposition',
    VERSION_FROM => 'lib/Physics/Electrodeposition.pm',
    ABSTRACT     => 'Model metal electrodeposition on semiconductor wafers',
    AUTHOR       => 'GitHub Copilot',
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM    => {
        'Carp'         => 0,
        'POSIX'        => 0,
        'Scalar::Util' => 0,
    },
    EXE_FILES    => [ glob('examples/*.pl') ],
);
