use v6;
use Test;

use Bread::Board;

# TODO: doing anything at all with the type object for a role with required
# methods is broken
#sub does_ok(Mu $var, Mu $type, $msg = ("The object does '" ~ $type.perl ~ "'")) {
sub does_ok(Mu $var, Mu $type, $msg = ("The object does [some role]")) {
    ok($var.does($type), $msg);
}

my $s = Bread::Board::BlockInjection.new(
    name         => 'NoClass',
    block        => -> $s { return { foo => $s.param('foo') } },
    dependencies => {
        foo => Bread::Board::Literal.new(name => 'foo', value => 'FOO');
    },
);

isa_ok($s, Bread::Board::BlockInjection);
does_ok($s, Bread::Board::Service);

my $x = $s.get;
isa_ok($x, Hash);
is_deeply($x, { foo => 'FOO' });

done;

# vim:ft=perl6:foldmethod=manual
