use v6;
use Test;

use Bread::Board;

# PERL6: doing anything at all with the type object for a role with required
# methods is broken
#sub does_ok(Mu $var, Mu $type, $msg = ("The object does '" ~ $type.perl ~ "'")) {
sub does_ok(Mu $var, Mu $type, $msg = ("The object does [some role]")) {
    ok($var.does($type), $msg);
}

class MyApp::Schema { }

class DBH {
    has ($.dsn, $.user, $.pass);
};

my $c = Bread::Board::Container.new(
    name     => 'Model',
    services => [
        Bread::Board::ConstructorInjection.new(
            name         => 'schema',
            class        => MyApp::Schema,
            dependencies => {
                dsn  => Bread::Board::Literal.new(name => 'dsn',  value => ''),
                user => Bread::Board::Literal.new(name => 'user', value => ''),
                pass => Bread::Board::Literal.new(name => 'pass', value => ''),
            },
        ),
        Bread::Board::BlockInjection.new(
            name  => 'dbh',
            block => -> $s {
                DBH.new(
                    dsn  => $s.param('dsn'),
                    user => $s.param('user'),
                    pass => $s.param('pass'),
                );
            },
            dependencies => {
                dsn  => Bread::Board::Literal.new(name => 'dsn',  value => ''),
                user => Bread::Board::Literal.new(name => 'user', value => ''),
                pass => Bread::Board::Literal.new(name => 'pass', value => ''),
            },
        ),
    ],
);

my $s = $c.fetch('dbh');
does_ok($s, Bread::Board::Service);

my $dbh = $s.get;
isa_ok($dbh, DBH);

done;

# vim:ft=perl6:foldmethod=manual
