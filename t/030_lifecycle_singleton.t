use v6;
use Test;

use Bread::Board;

# PERL6: doing anything at all with the type object for a role with required
# methods is broken
#sub does_ok(Mu $var, Mu $type, $msg = ("The object does '" ~ $type.perl ~ "'")) {
sub does_ok(Mu $var, Mu $type, $msg = ("The object does [some role]")) {
    ok($var.does($type), $msg);
}

class Needle { }
class Mexican::Black::Tar { }
class Addict {
    has ($.needle, $.spoon, $.stash);
}

my $s = Bread::Board::ConstructorInjection.new(
    lifecycle    => Singleton,
    name         => 'William',
    class        => Addict,
    dependencies => {
        needle => Bread::Board::ConstructorInjection.new(
            name  => 'spike',
            class => Needle,
        ),
        spoon => Bread::Board::Literal.new(
            name  => 'works',
            value => 'Spoon!',
        ),
    },
    parameters => {
        stash => { isa => Mexican::Black::Tar },
    },
);

isa_ok($s, Bread::Board::ConstructorInjection);
does_ok($s, Bread::Board::Service);

does_ok($s, Bread::Board::Singleton);
is($s.lifecycle.^name, 'Singleton');

ok(!$s.has_instance);
my $i = $s.get(stash => Mexican::Black::Tar.new);
ok($s.has_instance);

isa_ok($i, Addict);
isa_ok($i.needle, Needle);
is($i.spoon, 'Spoon!');
isa_ok($i.stash, Mexican::Black::Tar);

{
    my $i2 = $s.get(stash => Mexican::Black::Tar.new);
    is($i, $i2);
}

$s.flush_instance;

{
    my $i2 = $s.get(stash => Mexican::Black::Tar.new);
    isnt($i, $i2);

    {
        my $i2a = $s.get(stash => Mexican::Black::Tar.new);
        is($i2, $i2a);
    }
}

done;

# vim:ft=perl6:foldmethod=manual
