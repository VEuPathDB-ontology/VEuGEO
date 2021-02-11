# geocode_from_coordinates.pl

A demo script to perform the look-up from coordinates to placename.
This algorithm was used in VectorBase 2019-2021.

## Perl requirements:

- Geo::ShapeFile
- Encode::Detect::Detector

## Data requirements

Create a 'gadm' directory that is a sibling to the VEuGEO repo directory 

Download the full GADM shapefiles

`wget "https://biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip"`

Unpack only what we need

```
cd gadm
unzip gadm36_levels_shp.zip gadm36_[012].*
```

Then the `--gadm-stem` option to this script will not need changing (the default is `../../../gadm/gadm36`).