use v6;
use Test;

use Bread::Board;

class FileLogger {
    has $.log_file;
}

class MyApplication {
    has FileLogger $.logger;
}

my $c = container 'MyApp', {
    service 'log_file', 'logfile.log';

    service 'logger', (
        class        => FileLogger,
        lifecycle    => Singleton,
        dependencies => [
            depends_on('log_file'),
        ],
    );

    service 'application', (
        class        => MyApplication,
        dependencies => [
            depends_on('logger'),
        ],
    );
};

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
