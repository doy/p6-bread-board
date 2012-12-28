use v6;

use Bread::Board;

service 'logger', (
    class        => FileLogger,
    lifecycle    => Singleton,
    dependencies => {
        log_file => depends_on('log_file'),
    }
);
