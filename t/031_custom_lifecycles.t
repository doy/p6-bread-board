use v6;
use Test;

use Bread::Board;

# PERL6: doing anything at all with the type object for a role with required
# methods is broken
#sub does_ok(Mu $var, Mu $type, $msg = ("The object does '" ~ $type.perl ~ "'")) {
sub does_ok(Mu $var, Mu $type, $msg = ("The object does [some role]")) {
    ok($var.does($type), $msg);
}

role MyLifeCycle does Singleton { }

class MyClass { }

my $s = Bread::Board::ConstructorInjection.new(
    lifecycle => MyLifeCycle,
    name      => 'foo',
    class     => MyClass,
);

does_ok($s, MyLifeCycle);

done;

# vim:ft=perl6:foldmethod=manual
