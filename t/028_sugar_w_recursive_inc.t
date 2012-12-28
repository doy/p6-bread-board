use v6;
use Test;

use Bread::Board;

my $DIR = $*PROGRAM_NAME.split('/')[0..*-2].join('/');

class FileLogger {
    has $.log_file;
}

class MyApplication {
    has FileLogger $.logger;
}

my $c = include "$DIR/lib/my_app.bb";

my $logger = $c.resolve(service => 'logger');
isa_ok($logger, FileLogger);
is($logger.log_file, 'logfile.log');

is($c.fetch('logger/log_file').service, $c.fetch('log_file'));
is($c.fetch('logger/log_file').get, 'logfile.log');

my $app = $c.resolve(service => 'application');
isa_ok($app, MyApplication);

isa_ok($app.logger, FileLogger);
is($app.logger, $logger);

done;

# vim:ft=perl6:foldmethod=manual
