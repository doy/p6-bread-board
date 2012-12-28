use v6;

class Bread::Board::Container {...}
class Bread::Board::Dependency {...}

role Bread::Board::Traversable {
    has Bread::Board::Traversable $.parent is rw;

    method fetch (Str $path is copy) {
        # PERL6: substitutions don't return a useful value? # '
        # if $path ~~ s/^ \/ // {
        if $path ~~ m[^ '/' ] {
            $path ~~ s[^ '/' ] = '';
            return self.get_root_container._fetch($path);
        }
        else {
            return self.get_enclosing_container._fetch($path);
        }
    }

    method get_root_container {
        my $root = self;
        $root = $root.parent while $root.parent;
        return $root;
    }

    method get_enclosing_container {...}

    method _fetch (Str $path) {
        return self if $path eq '';

        my @parts = $path.split('/').grep(* ne '');
        my $rest = @parts[1..*-1].join('/');

        return $.parent._fetch($rest)
            if @parts[0] eq '..';

        return self._fetch_single(@parts[0])._fetch($rest);
    }

    method _fetch_single (Str $path) {...}
}

role Bread::Board::Service does Bread::Board::Traversable {
    has Str $.name;

    # PERL6: typed hashes NYI
    # has Hash of Bread::Board::Dependency $.dependencies = {};
    has $.dependencies = {};

    # PERL6: there doesn't appear to be any way for roles to do things at # '
    # construction time without breaking things - so, just call this method
    # in the constructor of all classes that use this role manually
    method _set_dependency_parents {
        for $.dependencies.values -> $dep {
            $dep.parent = self;
        }

        # PERL6: for loops are currently lazy, so won't get evaluated until # '
        # something evaluates the return value if they are the last statement
        # in a method. this may change in the future, because it's pretty # '
        # weird
        return;
    }

    method get {...}

    method get_dependency ($name) {
        return $.dependencies.{$name};
    }

    method get_enclosing_container {
        return $.parent;
    }

    method _fetch_single (Str $name) {
        # XXX parameters?
        return self.get_dependency($name)
            // die "No dependency $name found for $.name";
    }
}

role Bread::Board::HasParameters {
    # PERL6: typed hashes NYI
    # has Hash of Hash $.parameters = {};
    has $.parameters = {};

    method get_parameter (Str $name) {
        return $.parameters.{$name};
    }

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

        # PERL6: for loops are currently lazy, so won't get evaluated until # '
        # something evaluates the return value if they are the last statement
        # in a method. this may change in the future, because it's pretty # '
        # weird
        return;
    }
}

class Bread::Board::Dependency does Bread::Board::Traversable {
    has Str $.service_path;
    has Bread::Board::Service $.service handles 'get';

    # XXX is this the best way to do this?
    # we can't do it at construction time, since $.parent doesn't get set
    # until the current object is completely constructed
    method service {
        $!service //= self.fetch($.service_path);
        return $!service;
    }

    method get_enclosing_container {
        return $.parent.parent;
    }

    method _fetch_single (Str $name) {
        die "Can't fetch $name from a dependency";
    }
}

class Bread::Board::ConstructorInjection
    does Bread::Board::Service
    does Bread::Board::HasParameters {

    has $.class;
    has Str $.constructor_name is rw = 'new';

    # PERL6: type coercions NYI
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
        my $self = callwith(|%params);
        # XXX see above
        $self._set_dependency_parents;
        return $self;
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
    # XXX do we really want to keep this API? or should this really just be
    # the service object?
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

    # PERL6: type coercions NYI
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
        my $self = callwith(|%params);
        # XXX see above
        $self._set_dependency_parents;
        return $self;
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

class Bread::Board::Container does Bread::Board::Traversable {
    has Str $.name;
    # PERL6: typed hashes NYI
    # has Hash of Bread::Board::Container $.sub_containers = {};
    # has Hash of Bread::Board::Service $.services = {};
    has $.sub_containers = {};
    has $.services = {};

    # PERL6: type coercions NYI
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

    method get_enclosing_container { self }

    method _fetch_single (Str $name) {
        return self.get_sub_container($name)
            // self.get_service($name)
            // die "Couldn't find service or container for $name in $.name";
    }
}

# vim:ft=perl6:foldmethod=manual
