use v6;
use Test;

use Bread::Board;

class FileLogger {
    has $.log_file;
}

class DBI {
    has Str ($.dsn, $.username, $.password);

    method connect (Str $dsn, Str $username, Str $password) {
        self.new(dsn => $dsn, username => $username, password => $password);
    }
}

class MyApplication {
    has FileLogger $.logger;
    has DBI $.dbh;
}

my $c = container 'MyApp', {
    service 'log_file', 'logfile.log';
    service 'logger', (
        class        => FileLogger,
        lifecycle    => Singleton,
        dependencies => ['log_file'],
    );

    container 'Database', {
        service 'dsn', 'dbi:sqlite:dbname=my-app.db';
        service 'username', 'user';
        service 'password', 'pass';

        service 'dbh', (
            block => -> $s {
                DBI.connect(
                    $s.param('dsn'),
                    $s.param('username'),
                    $s.param('password'),
                ) || die "Could not connect";
            },
            dependencies => [qw[dsn username password]],
        );
    };

    service 'application', (
        class        => MyApplication,
        dependencies => ['logger', 'Database/dbh'],
    );
};

my $logger = $c.resolve(service => 'logger');
isa_ok($logger, FileLogger);
is($logger.log_file, 'logfile.log');

is($c.fetch('logger/log_file').service, $c.fetch('log_file'));
is($c.fetch('logger/log_file').get, 'logfile.log');

my $dbh = $c.resolve(service => 'Database/dbh');
isa_ok($dbh, DBI);

is($dbh.dsn, 'dbi:sqlite:dbname=my-app.db');
is($dbh.username, 'user');
is($dbh.password, 'pass');

my $app = $c.resolve(service => 'application');
isa_ok($app, MyApplication);

isa_ok($app.logger, FileLogger);
is($app.logger, $logger);

isa_ok($app.dbh, DBI);
isnt($app.dbh, $dbh);

done;

# vim:ft=perl6:foldmethod=manual
