use v6;
use Test;

use Bread::Board;

class MyApp::Schema { }
class MyApp::View::TT { }

my $c = container 'Application', {
    container 'Model', {
        service 'dsn', '';
        service 'schema', (
            class        => MyApp::Schema,
            dependencies => {
                dsn  => depends_on('dsn'),
                user => depends_on('user'),
                pass => depends_on('pass'),
            },
        );
    };
    container 'View', {
        service 'TT', (
            class        => MyApp::View::TT,
            dependencies => {
                tt_include_path => depends_on('include_path'),
            };
        );
    };
    container 'Controller';
};

my $model = $c.fetch('Model');
isa_ok($model, Bread::Board::Container);
is($model.name, 'Model');

{
    my $model2 = $c.fetch('/Model');
    isa_ok($model2, Bread::Board::Container);
    is($model, $model2);
}

my $dsn = $model.fetch('schema/dsn');
isa_ok($dsn, Bread::Board::Dependency);
is($dsn.service_path, 'dsn');

{
    my $dsn2 = $c.fetch('/Model/schema/dsn');
    isa_ok($dsn2, Bread::Board::Dependency);
    is($dsn, $dsn2);
}

my $root = $model.fetch('..');
isa_ok($root, Bread::Board::Container);
is($root, $c);

is($model, $model.fetch('../Model'));
is($dsn, $model.fetch('../Model/schema/dsn'));
is($model, $dsn.fetch('../Model'));

done;

# vim:ft=perl6:foldmethod=manual
