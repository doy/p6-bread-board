use v6;
use Test;

use Bread::Board;

class MyApp::Schema { }
class MyApp::View::TT { }

my $c = Bread::Board::Container.new(
    name           => 'Application',
    sub_containers => [
        Bread::Board::Container.new(
            name     => 'Model',
            services => [
                Bread::Board::Literal.new(name => 'dsn', value => ''),
                Bread::Board::ConstructorInjection.new(
                    name         => 'schema',
                    class        => MyApp::Schema,
                    dependencies => {
                        dsn => Bread::Board::Dependency.new(
                            service_path => 'dsn',
                        ),
                        user => Bread::Board::Literal.new(
                            name  => 'user',
                            value => '',
                        ),
                        pass => Bread::Board::Literal.new(
                            name  => 'pass',
                            value => '',
                        ),
                    },
                ),
            ],
        ),
        Bread::Board::Container.new(
            name     => 'View',
            services => [
                Bread::Board::ConstructorInjection.new(
                    name         => 'TT',
                    class        => MyApp::View::TT,
                    dependencies => {
                        tt_include_path => Bread::Board::Literal.new(
                            name  => 'include_path',
                            value => [],
                        ),
                    },
                ),
            ],
        ),
        Bread::Board::Container.new(name => 'Controller'),
    ],
);

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

my $root = $model.fetch('../');
isa_ok($root, Bread::Board::Container);
is($root, $c);
is($model, $model.fetch('../Model'));
is($dsn, $model.fetch('../Model/schema/dsn'));
is($model, $dsn.fetch('../Model'));

done;

# vim:ft=perl6:foldmethod=manual
