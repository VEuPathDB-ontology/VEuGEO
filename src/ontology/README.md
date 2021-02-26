# VBGEO.obo

VBGEO.obo was generated in April 2019 using

https://github.com/bobular/GADM-to-OBO/blob/master/gadm-to-obo.pl

As described at https://github.com/bobular/GADM-to-OBO, this script
transforms the first three levels of GADM, extracted from the
shapefiles available at
https://biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip (and
also available in Bob's home directory on yew) and a manually curated
'top level placename ontology'
(https://github.com/bobular/VB-top-level-GEO) into a .obo format
ontology file.

Note that the conversion also disambiguates all placenames (quite a complex operation).

# VEuGEO.obo

VEuGEO.obo was generated trivially by replacing VBGEO with VEuGEO with

`perl -npe s/VBGEO/VEuGEO/g VBGEO.obo > VEuGEO.obo`

Note the alt_id: field contains an ID that cross-references with GADM polygons.

# Next steps

- convert individual sources to OWL
  - top-level countries and continents
  - GADM country,ADM1,ADM2 hierachy
  - further manual edits
- set up tech to merge and manually resolve issues
- establish manual edit SOP

The above should handle these scenarios
- establish update process **if** a new GADM version is released
- establish update process if another source of admin region polygons is adopted

