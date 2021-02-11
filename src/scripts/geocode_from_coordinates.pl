#!/usr/bin/env perl
#                 -*- mode: cperl -*-
#
# usage: bin/geocode_from_coordinates.pl latitude longitude
#        or
#        bin/geocode_from_coordinates.pl latitude,longitude
#
# --gadm-stem ../../../gadm/gadm36       # location of gadmVV_N.{shp,dbf,...} files ("shapefile")
# --verbose                              # extra progress output
# --radius-degrees 0.025      # max distance in degrees to search around points that don't geocode (default = 1km)
# --steps 10                  # number of steps with which to do the search (increasing radius at each step)
#                             # use --steps 1 to disable the search
#
#
# DESCRIPTION
#
# Demo script for looking up GADM admin regions from coordinates.
#
# Using the lat/long coordinates it will look to see if this point is within any
# of the "level 0" GADM polygons.  The check is first done with precise lat/long given
# and then in an increasing spiral around that point (see --radius-degrees and --steps)
#
# If it is in one and one only polygon, this will be the country.
#
# Then it will check all the polygons in level 1 that are children of the level 0 term
# and if there's a single match that is the "admin 1" region.
# Then check its sub-polygons to assign "admin 2" region.
#
# Currently just prints to standard out, as it's just a demo.
#
# It's faster for subsequent lookups once all the data is in memory.
#

use strict;
use warnings;
use feature 'switch';
use lib 'lib';
use Getopt::Long;
use Scalar::Util qw(looks_like_number);
use List::MoreUtils;
use utf8::all;
use Geo::ShapeFile;
use Encode;  # for cleanup() func
use Encode::Detect::Detector;

my $gadm_stem = '../../../gadm/gadm36';
my $verbose;
my $max_radius_degrees = 0.025;
my $radius_steps = 10;

GetOptions("gadm_stem|gadm-stem=s"=>\$gadm_stem,
           "verbose"=>\$verbose,  # extra progress output to stderr
           "radius-degrees=s"=>\$max_radius_degrees,
           "steps|num-steps=i"=>\$radius_steps,
	  );


my ($lat, $long) = @ARGV;

die "must give coordinates on commandline\n" unless (defined $lat);

# split first arg into lat/long if necessary
($lat, $long) = split /\D+/, $lat unless (defined $long);

die "bad coordinates provided on commandline\n"
  unless (defined $lat && defined $long && looks_like_number($lat) && looks_like_number($long));

#
# initialise the shapefiles
#
my $shapefiles = [];
foreach my $level (0 .. 2) {
  $shapefiles->[$level] = Geo::ShapeFile->new(join '_', $gadm_stem, $level);
}

#
# do a demo lookup
#
lookup($lat, $long, $shapefiles, $max_radius_degrees, $radius_steps);


#
# main lookup function
#
sub lookup {
  my ($lat, $long, $shapefiles, $max_radius_degrees, $radius_steps) = @_;
  my $got_geo_term;
  my $pi = 3.14159265358979;
 RADIUS:
  for (my $radius=0; $radius<$max_radius_degrees; $radius += $max_radius_degrees/$radius_steps) {
    for (my $angle = 0; $radius==0 ? $angle<=0 : $angle<2*$pi; $angle += 2*$pi/8) { # try N, NE, E, SE, S etc
      # do the geocoding lookup
      my $query_point = Geo::ShapeFile::Point->new(X => $long + cos($angle)*$radius,
						   Y => $lat + sin($angle)*$radius);
      my $parent_id; # the ID, e.g. AFG of the higher level term that was geocoded

      foreach my $level (0 .. 2) {
	last if ($level > 0 && !defined $parent_id);
	# print "Scanning level $level\n" if $verbose;
	my $shapefile = $shapefiles->[$level];
	my $num_shapes = $shapefile->shapes;
	my @found_indices;
	foreach my $index (1 .. $num_shapes) {
	  if ($level == 0 || is_child_of_previous($index, $shapefile, $parent_id, $level-1)) {
	    my $shape = $shapefile->get_shp_record($index);
	    if ($shape->contains_point($query_point)) {
	      push @found_indices, $index;
	    }
	  }
	}
	if (@found_indices == 1) {
	  my $index = shift @found_indices;
	  my $dbf = $shapefile->get_dbf_record($index);
	  my $gadm_id = $dbf->{"GID_$level"};
	  my $gadm_name = cleanup($dbf->{"NAME_$level"});

	  $parent_id = $gadm_id;
	  $got_geo_term = $gadm_id;

	  print sprintf("Level %d found GADM %-16s name: %s\n", $level, $gadm_id, $gadm_name);

	} elsif (@found_indices > 0) {
	  warn "Warning: multiple polygons matched\n";
	}
      }
      last RADIUS if ($got_geo_term);
    }
  }
}

sub is_child_of_previous {
  my ($index, $shapefile, $parent_id, $level) = @_;
  my $dbf = $shapefile->get_dbf_record($index);
  return $dbf->{"GID_$level"} eq $parent_id;
}


# fix some issues with encodings and whitespace in place names

sub cleanup {
  my $string = shift;
  my $charset = detect($string);
  if ($charset) {
    # if anything non-standard, use UTF-8
    $string = decode("UTF-8", $string);
  }
  # remove leading and trailing whitespace
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  # fix any newlines or tabs with this
  $string =~ s/\s+/ /g;
  return $string;
}

