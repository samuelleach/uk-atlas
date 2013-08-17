<p align="center" >
  <img src="https://raw.github.com/samuelleach/uk-atlas/master/img/logo.png" alt="uk-atlas" title="uk-atlas">
</p>

This Makefile can be used to download various UK shapefiles and convert them to geojson and topojson formats. Currently we have:

- UK boundary.
- UK wards.
- England and Wales OAs, LSOAs and MSOAs.
- Scottish Datazones (equivalent to LSOAs) and Intermediate zones (MSOAs).
- England, Wales and Scotland postal areas and postal districts.
- England, Wales and Scotland counties and bouroughs.
- Ordnance Survey (OS) Boundary Line shapefiles ("electorial and administrative boundary information").
- OS Strategi ("a regional overview of road networks, railway lines, cities and rural wooded areas").
- OS Meridian 2 ("customisable for communication and topographical themes and route planning").
- English Green Belt 2011 regions.
- UK police force and fire service areas.
- Primary Care Organisations, Strategic Health Authorities, Clinical Commissioning Groups.

Run 'make all' to produce them. Required packages: topojson and ogr2ogr (gdal library).