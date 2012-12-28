use v6;
use Test;

use Bread::Board;

# TODO: doing anything at all with the type object for a role with required
# methods is broken
#sub does_ok(Mu $var, Mu $type, $msg = ("The object does '" ~ $type.perl ~ "'")) {
sub does_ok(Mu $var, Mu $type, $msg = ("The object does [some role]")) {
    ok($var.does($type), $msg);
}

class MyApp::Schema {}
class MyApp::View::TT {}

my $c = Bread::Board::Container.new(name => '/');
isa_ok($c, Bread::Board::Container);

$c.add_sub_container(
    Bread::Board::Container.new(
        name => 'Application',
        sub_containers => [
            Bread::Board::Container.new(
                name => 'Model',
                services => [
                    Bread::Board::Literal.new(name => 'dsn', value => ''),
                    Bread::Board::ConstructorInjection.new(
                        name         => 'schema',
                        class        => MyApp::Schema,
                        dependencies => {
                            dsn => Bread::Board::Dependency.new(
                                service_path => '../dsn',
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
                name => 'View',
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
            Bread::Board::Container.new(
                name => 'Controller',
            ),
        ],
    ),
);

my $app = $c.get_sub_container('Application');
isa_ok($app, Bread::Board::Container);

is($app.name, 'Application');

{
    my $controller = $app.get_sub_container('Controller');
    isa_ok($controller, Bread::Board::Container);
    is($controller.name, 'Controller');
    is($controller.parent, $app);
    ok(!$controller.has_services);
}

{
    my $view = $app.get_sub_container('View');
    isa_ok($view, Bread::Board::Container);
    is($view.name, 'View');
    is($view.parent, $app);
    ok($view.has_services);

    my $service = $view.get_service('TT');
    does_ok($service, Bread::Board::Service);
    is($service.parent, $view);
}

{
    my $model = $app.get_sub_container('Model');
    isa_ok($model, Bread::Board::Container);
    is($model.name, 'Model');
    is($model.parent, $app);
    ok($model.has_services);

    my $service = $model.get_service('schema');
    does_ok($service, Bread::Board::Service);
    is($service.parent, $model);
}

done;

# vim:ft=perl6:foldmethod=manual
