=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<XML::XSPF>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'XML::XSPF';
use Test2::Tools::Spec;
use Data::Dumper;

use XML::XSPF -all;

describe "class `$CLASS`" => sub {

	tests 'is an Exporter::Tiny' => sub {

		ok $CLASS->isa( 'Exporter::Tiny' );
	};

};

describe "function `playlist`" => sub {

	tests 'it works' => sub {

		my $called = 0;
		my $return = playlist {
			++$called;
			return 123;
		};

		is( $return, {}, 'it returned an empty hash' );
		is( $called, 1, 'it called the block' );
	};

	tests 'it cannot be nested in a playlist' => sub {

		my $e = dies {
			my $pl = playlist { my $pl2 = playlist {} };
		};

		like( $e, qr/Nested playlist/i, 'correct exception' );
		is( $CLASS->__current_playlist, U(), 'cleaned up playlist internals' );
	};

};

describe "function `track`" => sub {

	tests 'it works' => sub {

		my $called = 0;
		my $return = playlist {
			track {
				++$called;
				return 456;
			};
			return 123;
		};

		is( $return, { trackList => [ {} ] }, 'it added a track to the playlist' );
		is( $called, 1, 'it called the block' );
	};

	tests 'it cannot be nested in a track' => sub {

		my $e = dies {
			my $pl = playlist {
				track { track {} };
			};
		};

		like( $e, qr/Nested track/i, 'correct exception' );
		is( $CLASS->__current_playlist, U(), 'cleaned up playlist internals' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );
	};

	tests 'it must be nested in a playlist' => sub {

		my $e = dies {
			my $t = track {};
		};

		like( $e, qr/Track outside playlist/i, 'correct exception' );
		is( $CLASS->__current_playlist, U(), 'cleaned up playlist internals' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );
	};

};

describe "function `title`" => sub {

	tests 'it works' => sub {

		my $return = playlist {
			title "Quux";
			title "Foo";
			track {
				title "Bar";
				title "Baz";
			};
		};

		is( $return->{title}, 'Foo', 'can set playlist title' );
		is( $return->{trackList}[0]{title}, 'Baz', 'can set track title' );
	};

	tests 'it must be nested in a playlist or track' => sub {

		my $e = dies {
			my $t = title 'XYZ';
		};

		like( $e, qr/Title outside playlist or track/i, 'correct exception' );
		is( $CLASS->__current_playlist, U(), 'cleaned up playlist internals' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );
	};

};

describe "function `location`" => sub {

	tests 'it works' => sub {

		my $return = playlist {
			track {
				location "ABC";
				location "DEF";
			};
		};

		is( $return->{trackList}[0]{location}, 'DEF', 'can set track location' );
	};

	tests 'it must be nested in a track' => sub {

		my $e = dies {
			my $c = location 'XYZ';
		};

		like( $e, qr/Location outside track/i, 'correct exception' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );

		my $e2 = dies {
			my $c = playlist { location 'XYZ' };
		};

		like( $e2, qr/Location outside track/i, 'correct exception' );
		is( $CLASS->__current_playlist, U(), 'cleaned up playlist internals' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );
	};

};

describe "function `creator`" => sub {

	tests 'it works' => sub {

		my $return = playlist {
			track {
				creator "ABC";
				creator "DEF";
			};
		};

		is( $return->{trackList}[0]{creator}, 'DEF', 'can set track creator' );
	};

	tests 'it must be nested in a track' => sub {

		my $e = dies {
			my $c = creator 'XYZ';
		};

		like( $e, qr/Creator outside track/i, 'correct exception' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );

		my $e2 = dies {
			my $c = playlist { creator 'XYZ' };
		};

		like( $e2, qr/Creator outside track/i, 'correct exception' );
		is( $CLASS->__current_playlist, U(), 'cleaned up playlist internals' );
		is( $CLASS->__current_track,    U(), 'cleaned up track internals' );
	};

};

done_testing;
