=pod

=encoding utf-8

=head1 PURPOSE

Defines a simple playlist.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;
use XML::XSPF -all;

my $pl = playlist {
	title "80's Music";
	track {
		location "https://example.com/music/01.mp3";
		title "Take On Me";
		creator "A-ha";
	};
	track {
		location "https://example.com/music/02.mp3";
		title "Tainted Love";
		creator "Soft Cell";
	};
	track {
		location "https://example.com/music/03.mp3";
		title "Livin' on a Prayer";
		creator "Bon Jovi";
	};
};

is(
	$pl,
	{
		title => "80's Music",
		trackList => [
			{
				creator  => "A-ha",
				location => "https://example.com/music/01.mp3",
				title    => "Take On Me",
			},
			{
				creator  => "Soft Cell",
				location => "https://example.com/music/02.mp3",
				title    => "Tainted Love",
			},
			{
				creator  => "Bon Jovi",
				location => "https://example.com/music/03.mp3",
				title    => "Livin' on a Prayer",
			},
		],
	},
) or diag Dumper( $pl );

done_testing;

