use v6;
use Test;

use Bread::Board;

my $DIR = $?FILE.split('/')[0..*-2].join('/');

sub like ($str, Regex $rx, $reason = '') {
    ok($str ~~ $rx, $reason);
}

sub throws_ok (Callable $closure, Regex $rx, $reason = '') {
    try {
        $closure.();
        CATCH {
            # XXX is there a way to serialize $rx to something readable?
            like($_, $rx, $reason) || diag("$_ doesn't match the regex");
            default {}
        }
    }
}

# XXX better error?
throws_ok
    { include "$DIR/lib/bad.bb" },
    rx/"Undeclared routine" .* function_doesnt_exist/;
throws_ok
    { include "$DIR/lib/doesnt_exist.bb" },
    rx/"Unable to open" .* "doesnt_exist.bb"/;
throws_ok
    { include "$DIR/lib/false.bb" },
    rx/"false.bb" .* "doesn't return a true value"/;

class FileLogger {
    has $.log_file;
}

class MyApplication {
    has FileLogger $.logger;
}

my $c = container 'MyApp', {
    service 'log_file', 'logfile.log';

    include "$DIR/lib/logger.bb";

    service 'application', (
        class => MyApplication,
        dependencies => {
            logger => depends_on('logger'),
        },
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
