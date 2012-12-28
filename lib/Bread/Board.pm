use v6;

class Bread::Board::Container {...}
class Bread::Board::Dependency {...}

role Bread::Board::Service {
    has Str $.name;
    has Bread::Board::Container $.parent is rw = Bread::Board::Container;

    # TODO: typed hashes NYI
    # has Hash of Bread::Board::Dependency $.dependencies = {};
    has $.dependencies = {};

    method get {*};

    method get_dependency ($name) {
        return $.dependencies.{$name};
    }
}

role Bread::Board::HasParameters {
    # TODO: typed hashes NYI
    # has Hash of Hash $.parameters = {};
    has $.parameters = {};

    method check_parameters (%params) {
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

        # TODO: for loops are currently lazy, so won't get evaluated until # '
        # something evaluates the return value if they are the last statement
        # in a method. this may change in the future, because it's pretty # '
        # weird
        return;
    }
}

class Bread::Board::Dependency {
    has Bread::Board::Service $.service handles 'get';
}

class Bread::Board::ConstructorInjection
    does Bread::Board::Service
    does Bread::Board::HasParameters {

    has $.class;
    has Str $.constructor_name is rw = 'new';

    # TODO: type coercions NYI
    method new (*%params is copy) {
        if %params.<dependencies> {
            my $deps = {};
            for %params.<dependencies>.keys -> $name {
                my $dep = %params.<dependencies>.{$name};
                $deps.{$name} = $dep.isa(Bread::Board::Dependency)
                    ?? $dep
                    !! Bread::Board::Dependency.new(service => $dep);
            }
            %params.<dependencies> = $deps;
        }
        nextwith(|%params);
    }

    method get (*%params is copy) {
        # XXX remove more duplication?
        self.check_parameters(%params);
        for $.dependencies.keys -> $name {
            %params{$name} = $.dependencies{$name}.get;
        }
        return $.class."$.constructor_name"(|%params);
    }
}

class Bread::Board::Parameters {
    has Hash $.params;
    # XXX do we really want to keep this API?
    has $.class;

    method param (Str $name) {
        return $.params.{$name};
    }
}

class Bread::Board::BlockInjection
    does Bread::Board::Service
    does Bread::Board::HasParameters {

    has Callable $.block;
    has $.class = Any;

    # TODO: type coercions NYI
    method new (*%params is copy) {
        if %params.<dependencies> {
            my $deps = {};
            for %params.<dependencies>.keys -> $name {
                my $dep = %params.<dependencies>.{$name};
                $deps.{$name} = $dep.isa(Bread::Board::Dependency)
                    ?? $dep
                    !! Bread::Board::Dependency.new(service => $dep);
            }
            %params.<dependencies> = $deps;
        }
        nextwith(|%params);
    }

    method get (*%params is copy) {
        # XXX remove more duplication?
        self.check_parameters(%params);
        for $.dependencies.keys -> $name {
            %params{$name} = $.dependencies{$name}.get;
        }
        return $.block.(
            Bread::Board::Parameters.new(
                params => %params,
                class  => $.class,
            )
        );
    }
}

class Bread::Board::Literal does Bread::Board::Service {
    has $.value;

    method get {
        return $.value;
    }
}

class Bread::Board::Container {
    has Str $.name;
    has Bread::Board::Container $.parent is rw = Bread::Board::Container;
    # TODO: typed hashes NYI
    # has Hash of Bread::Board::Container $.sub_containers = {};
    # has Hash of Bread::Board::Service $.services = {};
    has $.sub_containers = {};
    has $.services = {};

    # TODO: type coercions NYI
    method new (*%params is copy) {
        if %params.<sub_containers>.isa(Array) {
            %params.<sub_containers> = %params.<sub_containers>.map(-> $c { $c.name => $c }).hash;
        }
        if %params.<services>.isa(Array) {
            %params.<services> = %params.<services>.map(-> $c { $c.name => $c }).hash;
        }
        my $container = callwith(|%params);
        if %params.<sub_containers>:exists {
            for %params.<sub_containers>.values -> $c {
                $c.parent = $container;
            }
        }
        if %params.<services>:exists {
            for %params.<services>.values -> $c {
                $c.parent = $container;
            }
        }
        return $container;
    }

    method add_sub_container (Bread::Board::Container $c) {
        $.sub_containers.{$c.name} = $c;
        $c.parent = self;
    }

    method get_sub_container (Str $name) {
        return $.sub_containers.{$name};
    }

    method has_services {
        return $.services > 0;
    }

    method get_service (Str $name) {
        return $.services.{$name};
    }
}
