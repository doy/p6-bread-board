use v6;
use Test;

use Bread::Board;

class FileLogger {
    has $.log_file;
}

class MyApplication {
    has FileLogger $.logger;
}

sub loggers {
    service 'log_file', 'logfile.log';
    service 'logger', (
        class     => FileLogger,
        lifecycle => Singleton,
        dependencies => {
            log_file => depends_on('log_file'),
        },
    );
}

my $c = container 'MyApp';

Bread::Board::set_root_container($c);

lives_ok { Bread::Board::set_root_container($c) };
lives_ok { Bread::Board::set_root_container(Bread::Board::Container) };

container $c, {
    dies_ok { Bread::Board::set_root_container(Bread::Board::Container) };
};

Bread::Board::set_root_container($c);

loggers(); # reuse baby !!!

service 'application', (
    class        => MyApplication,
    dependencies => {
        logger => depends_on('logger'),
    },
);

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
