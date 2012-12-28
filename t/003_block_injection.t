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
    has $.needle;
    has $.spoon;
    has $.stash;

    method shoot_up_good (Addict $class: *%args) {
        $class.new(|%args, overdose => 1);
    }
}

{
    my $s = Bread::Board::BlockInjection.new(
        name => 'William',
        class => Addict,
        block => -> $s { $s.class.new(|$s.params) },
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

    isa_ok($s, Bread::Board::BlockInjection);
    does_ok($s, Bread::Board::Service);

    {
        my $i = $s.get(stash => Mexican::Black::Tar.new);
        isa_ok($i, Addict);
        isa_ok($i.needle, Needle);
        is($i.spoon, 'Spoon!');
        isa_ok($i.stash, Mexican::Black::Tar);

        my $i2 = $s.get(stash => Mexican::Black::Tar.new);
        isnt($i, $i2);
    }

    is($s.name, 'William');
    is($s.class.perl, Addict.perl);

    my $deps = $s.dependencies;
    is_deeply([$deps.keys.sort], [qw/needle spoon/]);

    my $needle = $s.get_dependency('needle');
    isa_ok($needle, Bread::Board::Dependency);
    isa_ok($needle.service, Bread::Board::ConstructorInjection);
    is($needle.service.name, 'spike');
    is($needle.service.class.perl, Needle.perl);

    my $spoon = $s.get_dependency('spoon');
    isa_ok($spoon, Bread::Board::Dependency);
    isa_ok($spoon.service, Bread::Board::Literal);
    is($spoon.service.name, 'works');
    is($spoon.service.value, 'Spoon!');

    my $params = $s.parameters;
    is_deeply([$params.keys.sort], [qw/stash/]);
    is_deeply($params.<stash>, { isa => Mexican::Black::Tar });

    dies_ok { $s.get };
    dies_ok { $s.get(stash => []) };
    dies_ok { $s.get(stash => Mexican::Black::Tar.new, foo => 10) };
}

done;

# vim:ft=perl6:foldmethod=manual
