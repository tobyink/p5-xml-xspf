use 5.010001;
use strict;
use warnings;

package XML::XSPF;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Carp qw( croak );
use Exporter::Shiny qw(
	playlist
	track
	title
	creator
	location
);
use Scope::Guard qw( guard );

my %CURRENT;

sub __current {
	return \%CURRENT; # useful for unit tests
}

sub playlist (&) {
	my $block = shift;

	$CURRENT{playlist} and croak( "Nested playlist" );
	$CURRENT{playlist} = {};
	my $guard = guard { delete $CURRENT{playlist} };
	$block->();

	return $CURRENT{playlist};
}

sub track (&) {
	my $block = shift;

	$CURRENT{track} and croak( "Nested track" );
	$CURRENT{playlist} or croak( "Track outside playlist" );
	$CURRENT{track} = {};
	my $guard = guard { delete $CURRENT{track} };
	$block->();
	push @{ $CURRENT{playlist}->{trackList} //= [] }, $CURRENT{track};

	return;
}

sub title ($) {
	my $title = shift;

	my $target = $CURRENT{track} // $CURRENT{playlist} // croak( "Title outside playlist or track" );
	$target->{title} = $title;

	return;
}

sub location ($) {
	my $location = shift;

	my $target = $CURRENT{track} // croak( "Location outside track" );
	$target->{location} = $location;

	return;
}

sub creator ($) {
	my $creator = shift;

	my $target = $CURRENT{track} // croak( "Creator outside track" );
	$target->{creator} = $creator;

	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

XML::XSPF - DSL for a subset of XSPF data

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a quick demo for creating a DSL in Perl.

=head2 FUNCTIONS

None are exported by default. C<< use XML::XSPF -all >> to import them all
into your namespace. C<< use XML::XSPF qw( playlist track location ) >> to
export some by name. C<< use XML::XSPF -all, -lexical >> to import lexically.

=head3 C<< playlist >>

Returns a playlist. Should be followed by a block setting an optional title
for the playlist, and zero or more tracks.

=head3 C<< track >>

Must only be used within a playlist. Should be followed by a block setting
an optional title, creator, and location for the track. Returns nothing.

=head3 C<< title >>

Used within a playlist or track, sets the title. Returns nothing.

=head3 C<< creator >>

Used within a track, sets the creator. Returns nothing.

=head3 C<< location >>

Used within a track, sets the location (a file path or URL). Returns nothing.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-xml-xspf/issues>.

=head1 SEE ALSO

L<https://xspf.org/spec>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
