use v6;

use Bread::Board;

say $*PROGRAM_NAME;
my $DIR = $*PROGRAM_NAME.split('/')[0..*-2].join('/');

container 'MyApp', {

    service 'log_file', "logfile.log";

    include "$DIR/lib/logger.bb";

    service 'application', (
        class        => MyApplication,
        dependencies => {
            logger => depends_on('logger'),
        }
    );
};

# vim:ft=perl6:foldmethod=manual
