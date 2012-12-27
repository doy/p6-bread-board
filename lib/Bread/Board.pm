use v6;

class Bread::Board::Dependency {...}

role Bread::Board::Service {
    has Str $.name;

    # XXX not sure how to make these optional - specifying the types here
    # makes it fail when the parameters aren't passed
    # shouldn't the " = {}" part be taking care of that?
    # has Hash of Bread::Board::Dependency $.dependencies = {};
    # has Hash of Hash $.parameters = {};
    has $.dependencies = {};
    has $.parameters = {};

    # XXX overriding new here is an extremely suboptimal solution
    # does perl 6 have anything like moose's coercions?
    method new (*%params is copy) {
        if %params.<dependencies> {
            my $deps = {};
            for %params.<dependencies>.keys -> $dep {
                $deps.{$dep} = Bread::Board::Dependency.new(
                    service => %params.<dependencies>.{$dep},
                );
            }
            %params.<dependencies> = $deps;
        }
        nextwith(|%params);
    }

    method get {*};

    method get_dependency ($name) {
        return $.dependencies.{$name};
    }
}

class Bread::Board::Dependency {
    has Bread::Board::Service $.service handles 'get';
}

class Bread::Board::ConstructorInjection does Bread::Board::Service {
    has $.class;
    has Str $.constructor_name is rw = 'new';

    method get (*%params is copy) {
        self.check_parameters(%params);
        for $.dependencies.keys -> $name {
            %params{$name} = $.dependencies{$name}.get;
        }
        return $.class."$.constructor_name"(|%params);
    }

    my method check_parameters (%params) {
        for $.parameters.keys -> $name {
            if not %params.{$name}:exists {
                die "Required parameter $name not given";
            }
        }

        for %params.keys -> $name {
            if not $.parameters.{$name}:exists {
                die "Unknown parameter $name given";
            }
            if not %params.{$name}.isa($.parameters.{$name}.<isa>) {
                die "{%params.{$name}.perl} is not a valid value for the $name parameter";
            }
        }

        # XXX why is this return necessary?
        return;
    }
}

class Bread::Board::Literal does Bread::Board::Service {
    has $.value;

    method get {
        return $.value;
    }
}
