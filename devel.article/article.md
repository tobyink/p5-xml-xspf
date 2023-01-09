# Creating a Simple DSL in Perl

Let's look at the XSPF playlist format. It's a pretty simple XML-based
file format.

    <?xml version="1.0" encoding="UTF-8"?>
    <playlist version="1" xmlns="http://xspf.org/ns/0/">
      <title>80's Music</title>
      <trackList>
        <track>
          <title>Take On Me</title>
          <creator>A-ha</creator>
          <location>https://example.com/music/01.mp3</location>
        </track>
        <track>
          <title>Tainted Love</title>
          <creator>Soft Cell</creator>
          <location>https://example.com/music/02.mp3</location>
        </track>
        <track>
          <title>Livin' on a Prayer</title>
          <creator>Bon Jovi</creator>
          <location>https://example.com/music/03.mp3</location>
        </track>
        </track>
      </trackList>
    </playlist>

The [full specification](https://xspf.org/spec) has a lot more details, but
for now, we'll just use those elements.

If we are building a Perl application that needs to allow less experienced
users to write playlists in Perl, it might be useful to define a
domain-specific dialect of Perl for writing playlists.

Something like this:

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

It is actually pretty simple to do this!

## The `playlist` function

A simple implementation of the `playlist` function is this:

    my $current_playlist;
    
    sub playlist (&) {
      my $block = shift;
      $current_playlist = {};
      $block->();
      return $current_playlist;
    }

The prototype of `(&)` allows a function to accept a block of code.
Our `playlist` function wants to create a blank playlist (which we'll
implement as an empty hashref), run the block (which will define the tracks),
and then return the playlist.

The reason that the `$current_playlist` variable is declared _outside_
the function is so that other functions (such as `title`) can access it.

Here's an implementation for `title`:

    sub title ($) {
      my $string = shift;
      $current_playlist->{title} = $string;
      return;
    }

And we'll use [Exporter::Shiny](https://metacpan.org/pod/Exporter%3A%3AShiny) to export our functions. Other exporters
also exist.

    use Exporter::Shiny qw( playlist title );

Let's test it:

    use XML::XSPF -all;
    use Test2::V0;
    
    my $pl = playlist {
      title "Test 123";
    };
    
    is( $pl, { title => "Test 123" } );
    
    done_testing;

Yay! It works!

## Some sanity checks

We should add some checks to make sure `title` is only ever used inside
a playlist, and also ensure that playlists are not nested.

    use Carp qw( croak );
    use Scope::Guard qw( guard );
    
    my $current_playlist;
    
    sub playlist (&) {
      
      my $block = shift;
      
      $current_playlist and croak( "Nested playlist" )
      $current_playlist = {};
      my $guard = guard { undef $current_playlist };
      
      $block->();
      
      return $current_playlist;
    }
    
    sub title ($) {
      
      my $string = shift;
      
      $current_playlist or croak( "Title outside playlist" );
      
      $current_playlist->{title} = $string;
      return;
    }

Using a `guard` to undef `$current_playlist` at the end of building
a playlist ensures it will always happen, even if the block throws an
exception, so we never end up with `$current_playlist` remaining dirty
at the end of a `playlist` block.

## Expanding on all that

Expanding upon these ideas to also provide `track`, `creator`, and
`location` functions, we get:

    use 5.010001;
    use strict;
    use warnings;
    
    package XML::XSPF;
    
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

And here's a simple test:

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

If you try it out, it should pass.

## Next steps

A good next step might be for `playlist` to build a blessed
`XML::XSPF::Playlist` object, and `track` to build blessed
`XML::XSPF::Track` objects. `XML::XSPF::Playlist` could
offer a `to_xml` method.

These improvements are left as an exercise to the reader.
