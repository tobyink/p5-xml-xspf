use 5.010001;
use strict;
use warnings;

package XML::XSPF;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

# Utility functions we need.
use Carp qw( croak );
use Scope::Guard qw( guard );

# Functions we will export.
use Exporter::Shiny qw(
	playlist
	track
	title
	creator
	location
);

# Scratchpad for storing playlists and tracks while they are
# being built.
my $current_playlist;
my $current_track;

# Private functions useful for unit tests.
sub __current_playlist { $current_playlist }
sub __current_track    { $current_track }

# Function called to define a new playlist.
sub playlist (&) {

	# It accepts a block of Perl code (which will define tracks, etc).
	my $block = shift;

	# Ensure that there isn't already a half-built playlist, and then
	# start building one. The guard ensures that the playlist will be
	# cleaned up at the end of this function, even if an exception gets
	# thrown later.
	$current_playlist and croak( "Nested playlist" );
	$current_playlist = {};
	my $guard = guard { undef $current_playlist };

	# Run the block we were given.
	$block->();

	# Return the complete playlist.
	return $current_playlist;
}

# Function called to define a new track.
sub track (&) {

	# It accepts a block of Perl code (which will add track details).
	my $block = shift;

	# Ensure that there isn't already a half-built track, and we haven't
	# been called outside a playlist, and then start building a track.
	# The guard ensures that the track will be cleaned up at the end of
	# this function, even if an exception gets thrown later.
	$current_track and croak( "Nested track" );
	$current_playlist or croak( "Track outside playlist" );
	$current_track = {};
	my $guard = guard { undef $current_track };

	# Run the block we were given.
	$block->();

	# Add the built track to the playlist. Return nothing.
	push @{ $current_playlist->{trackList} //= [] }, $current_track;
	return;
}

# Function to set the title for current track or playlist.
sub title ($) {

	# It accepts a string.
	my $string = shift;

	# If there's a track being built, that's the target. Otherwise,
	# the target is the playlist being built. It's an error to call
	# this function if neither is being built.
	my $target = $current_track // $current_playlist;
	$target // croak( "Title outside playlist or track" );

	# Set the title. Return nothing.
	$target->{title} = $string;
	return;
}

# Function to set the location for current track.
sub location ($) {

	# It accepts a string.
	my $string = shift;

	# It's an error to call this function if no track is being built.
	$current_track // croak( "Location outside track" );

	# Set the location of the current track. Return nothing.
	$current_track->{location} = $string;
	return;
}

# Function to set the creator for current track.
sub creator ($) {

	# It accepts a string.
	my $string = shift;

	# It's an error to call this function if no track is being built.
	$current_track // croak( "Creator outside track" );

	# Set the creator of the current track. Return nothing.
	$current_track->{creator} = $string;
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
