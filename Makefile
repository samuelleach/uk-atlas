# This is a Makefile for producing various UK geojson and topojson files.

NATURALEARTH=http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural
ONS=http://data.statistics.gov.uk/ONSGeography/CensusGeography/Boundaries/2011
GEOLYTIX=http://geolytix.co.uk/downloads
ONS2=https://geoportal.statistics.gov.uk/Docs/Boundaries
SNS=http://www.sns.gov.uk/BulkDownloads
SHAREGEO=http://www.sharegeo.ac.uk/download
EXTRACTOTRON=http://osm-extracted-metros.s3.amazonaws.com
OSMPLANET=http://planet.openstreetmap.org
NATURALENGLAND=http://www.gis.naturalengland.org.uk/pubs/gis/GIS_selection.asp # Further open data resources here
# http://www.gis.naturalengland.org.uk/pubs/gis/GIS_Selection.asp?Type=2
	
OS_STRTGI_SHP = \
		a_road b_road foreshor_region national_park rivers_line \
		woodland_region admin_line coastline \
		primary_road ferry_box gridlines minor_road \
		railway_line antiquity_line ferry_line lakes_region \
		motorway urban_region
		# land_use_seed tourist_symbol general_text land_use_symbol road_point \
		# transport_symbol admin_seed settlement_seed transport_text railway_point spot_height

OS_MERIDIAN2_SHP = \
		a_road_polyline coast_ln_polyline dlua_region \
		river_polyline woodland_region admin_ln_polyline \
		county_region motorway_polyline \
		b_road_polyline district_region lake_region rail_ln_polyline
		# minor_rd_polyline roadnode_point #out of memory on these one
		# settlemt_point junction_font_point rndabout_point station_point text

SHAREGEO_SHP = \
		GreenBelt2011 uk_police_force_areas fire_service_areas

SHAREGEO_HEALTH_SHP = \
		LHB_DEC_2011_WA_BFC PCO_DEC_2011_EN_BFC SHA_DEC_2011_EN_BFC

all: topo/ne/uk.json \
	topo/ons/ukwards.topo.json \
	topo/geolytix/PostalArea.topo.json \
	topo/geolytix/PostalDistrict.topo.json \
	# topo/ons/england_wales_oa_2011.topo.json \
	# topo/ons/england_wales_lsoa_2011.topo.json \
	# topo/ons/england_wales_msoa_2011.topo.json \
	# topo/sns/scotland_datazone_2001.topo.json \
	topo/sns/scotland_intermediatezone_2001.topo.json \
	topo/os/bdline_gb/Data/county_region.topo.json \
	topo/os/bdline_gb/Data/district_borough_unitary_region.topo.json \
	topo/os/bdline_gb/Data/european_region_region.topo.json \
	topo/os/bdline_gb/Data/county_electoral_division_region.topo.json \
	topo/os/bdline_gb/Data/unitary_electoral_division_region.topo.json \
	topo/os/bdline_gb/Data/district_borough_unitary_ward_region.topo.json \
	topo/os/bdline_gb/Data/district_borough_unitary_region.topo.json \
	topo/os/bdline_gb/Data/parish_region.topo.json \
	topo/os/bdline_gb/Data/scotland_and_wales_region_region.topo.json \
	topo/os/bdline_gb/Data/westminster_const_region.topo.json \
	topo/os/bdline_gb/Data/greater_london_const_region.topo.json \
	topo/os/bdline_gb/Data/high_water_polyline.topo.json \
	$(addprefix topo/os/strtgi_essh_gb/data/, $(addsuffix .topo.json, $(OS_STRTGI_SHP))) \
	$(addprefix topo/os/merid2_essh_gb/data/, $(addsuffix .topo.json, $(OS_MERIDIAN2_SHP))) \
	$(addprefix topo/sharegeo/, $(addsuffix .topo.json, $(SHAREGEO_SHP))) \
	$(addprefix topo/sharegeo/MYDATA_121312/, $(addsuffix .topo.json, $(SHAREGEO_HEALTH_SHP)))

clean:
	rm -rf gz bz2 shp pbf topo ons sns os

tidy:
	rm -rf *.README.html *.VERSION.txt *.prj

# UK Boundary from Natural Earth data
gz/ne/%.zip:
	mkdir -p $(dir $@) && wget $(NATURALEARTH)/$(notdir $@) -O $@.download && mv $@.download $@

#Note that ogr2ogr requires the .shp, .shx and .dbf files to work.
shp/ne/%.shp: gz/ne/%.zip
	mkdir -p $(dir $@) && unzip $< -d $(dir $@)
	touch $@
	make tidy

topo/ne/subunits.json: shp/ne/ne_10m_admin_0_map_subunits.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-f GeoJSON \
		-where "adm0_a3 IN ('GBR', 'IRL')" \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@
	
topo/ne/places.json: shp/ne/ne_10m_populated_places.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-f GeoJSON \
		-where "iso_a2 = 'GB' AND SCALERANK < 8" \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@	

topo/ne/uk.json: topo/ne/subunits.json topo/ne/places.json
	mkdir -p $(dir $@)
	topojson \
		--id-property su_a3 \
		-p name=NAME \
		-p name \
		-o $@ \
		topo/ne/subunits.json \
		topo/ne/places.json

# English Wards, from Office of National Statistics.
ons/WD_DEC_2011_EW_BGC_shp.zip: 
	mkdir -p $(dir $@) && wget $(ONS)/Wards/$(notdir $@) -O $@.download && mv $@.download $@

shp/ons/WD_DEC_2011_EW_BGC.shp: ons/WD_DEC_2011_EW_BGC_shp.zip
	mkdir -p $(dir $@) && unzip $< -d $(dir $@)
	touch $@

topo/ons/ukwards.json: shp/ons/WD_DEC_2011_EW_BGC.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@

topo/ons/ukwards.topo.json: topo/ons/ukwards.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property WD11CD \
		--properties WD11NM \
		--simplify-proportion 0.5

# England and Wales OAs from ONS
ons/Output_areas_(E+W)_2011_Boundaries_(Generalised_Clipped).zip:
	mkdir -p $(dir $@) && wget --no-check-certificate $(ONS2)/Output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip -O tmp.download && mv tmp.download $(dir $@)/Output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip
	touch $(dir $@)/Output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip

shp/ons/OA_2011_EW_BGC.shp: ons/Output_areas_(E+W)_2011_Boundaries_(Generalised_Clipped).zip
	mkdir -p $(dir $@) && unzip -u ons/Output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip -d $(dir $@)
	touch $@

topo/ons/england_wales_oa_2011.json: shp/ons/OA_2011_EW_BGC.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@

topo/ons/england_wales_oa_2011.topo.json: topo/ons/england_wales_oa_2011.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property OA11CD \
		--properties \
		--simplify-proportion 0.2

# England and Wales LSOAs from ONS
ons/Lower_layer_super_output_areas_(E+W)_2011_Boundaries_(Generalised_Clipped).zip:
	mkdir -p $(dir $@) && wget --no-check-certificate $(ONS2)/Lower_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip -O tmp.download && mv tmp.download $(dir $@)/Lower_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip
	touch $(dir $@)/Lower_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip

shp/ons/LSOA_2011_EW_BGC.shp: ons/Lower_layer_super_output_areas_(E+W)_2011_Boundaries_(Generalised_Clipped).zip
	mkdir -p $(dir $@) && unzip -u ons/Lower_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip -d $(dir $@)
	touch $@

topo/ons/england_wales_lsoa_2011.json: shp/ons/LSOA_2011_EW_BGC.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@

topo/ons/england_wales_lsoa_2011.topo.json: topo/ons/england_wales_lsoa_2011.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property LSOA11CD \
		--properties \
		--simplify-proportion 0.2

# England and Wales MSOAs from ONS
ons/Middle_layer_super_output_areas_(E+W)_2011_Boundaries_(Generalised_Clipped).zip:
	mkdir -p $(dir $@) && wget --no-check-certificate $(ONS2)/Middle_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip -O tmp.download && mv tmp.download $(dir $@)/Middle_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip
	touch $(dir $@)/Middle_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip

shp/ons/MSOA_2011_EW_BGC.shp: ons/Middle_layer_super_output_areas_(E+W)_2011_Boundaries_(Generalised_Clipped).zip
	mkdir -p $(dir $@) && unzip -u ons/Middle_layer_super_output_areas_\(E+W\)_2011_Boundaries_\(Generalised_Clipped\).zip -d $(dir $@)
	touch $@

topo/ons/england_wales_msoa_2011.json: shp/ons/MSOA_2011_EW_BGC.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@

topo/ons/england_wales_msoa_2011.topo.json: topo/ons/england_wales_msoa_2011.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property MSOA11CD \
		--properties \
		--simplify-proportion 0.2

# Scottish data zones from Scottish Neighbourhood Statistics
sns/SNS_Geography_14_3_2013.zip: 
	mkdir -p $(dir $@) && wget $(SNS)/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/sns/DataZone_2001_bdry.shp: sns/SNS_Geography_14_3_2013.zip
	mkdir -p $(dir $@) && unzip -u $< -d $(dir $@)
	touch $@

topo/sns/scotland_datazone_2001.json: shp/sns/DataZone_2001_bdry.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@

topo/sns/scotland_datazone_2001.topo.json: topo/sns/scotland_datazone_2001.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property DZ_CODE \
		--properties \
		--simplify-proportion 0.5

# Scottish intermediate zones from Scottish Neighbourhood Statistics
shp/sns/IntermediateZone_2001_bdry.shp: sns/SNS_Geography_14_3_2013.zip
	mkdir -p $(dir $@) && unzip -u $< -d $(dir $@)
	touch $@

topo/sns/scotland_intermediatezone_2001.json: shp/sns/IntermediateZone_2001_bdry.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../$@

topo/sns/scotland_intermediatezone_2001.topo.json: topo/sns/scotland_intermediatezone_2001.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property IZ_CODE \
		--properties \
		--simplify-proportion 0.5

# English and Scottish postal boundaries from Geolytix.
gz/geolytix/PostalBoundariesOpen2012.zip: 
	mkdir -p $(dir $@) && wget $(GEOLYTIX)/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/geolytix/PostalBoundariesSHP/%.shp: gz/geolytix/PostalBoundariesOpen2012.zip
	rm -rf $(dir $@) && mkdir -p $(dir $@) && unzip $< -d $(dir $@) && unzip shp/geolytix/PostalBoundariesSHP/PostalBoundariesSHP.zip -d $(dir $@)
	touch $(dir $@)/*

topo/geolytix/PostalArea.json: shp/geolytix/PostalBoundariesSHP/PostalArea.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../../$@

topo/geolytix/PostalArea.topo.json: topo/geolytix/PostalArea.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property PostArea \
		--properties \
		--simplify-proportion 0.2

topo/geolytix/PostalDistrict.json: shp/geolytix/PostalBoundariesSHP/PostalDistrict.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../../$@

topo/geolytix/PostalDistrict.topo.json: topo/geolytix/PostalDistrict.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property PostDist \
		--properties \
		--simplify-proportion 0.2

topo/geolytix/PostalDistrict_v2.json: shp/geolytix/PostalBoundariesSHP/PostalDistrict_v2.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<); \
	mv $(notdir $@) ../../../$@

topo/geolytix/PostalDistrict_v2.topo.json: topo/geolytix/PostalDistrict_v2.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--id-property PostDist \
		--properties \
		--simplify-proportion 0.2

# Boundary Line data from Ordnance survey
shp/os/bdline_gb/%.shp: os/bdline_gb.zip
	mkdir -p shp/$(basename $<) && unzip -u $< -d shp/$(dir $<)
	touch $@

topo/os/bdline_gb/Data/county_region.topo.json: topo/os/bdline_gb/Data/county_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/district_borough_unitary_region.topo.json: topo/os/bdline_gb/Data/district_borough_unitary_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/european_region_region.topo.json: topo/os/bdline_gb/Data/european_region_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/county_electoral_division_region.topo.json: topo/os/bdline_gb/Data/county_electoral_division_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/unitary_electoral_division_region.topo.json: topo/os/bdline_gb/Data/unitary_electoral_division_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/district_borough_unitary_ward_region.topo.json: topo/os/bdline_gb/Data/district_borough_unitary_ward_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/parish_region.topo.json: topo/os/bdline_gb/Data/parish_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/scotland_and_wales_region_region.topo.json: topo/os/bdline_gb/Data/scotland_and_wales_region_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/westminster_const_region.topo.json: topo/os/bdline_gb/Data/westminster_const_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/greater_london_const_region.topo.json: topo/os/bdline_gb/Data/greater_london_const_region.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/os/bdline_gb/Data/high_water_polyline.topo.json: topo/os/bdline_gb/Data/high_water_polyline.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

# Strategi data from Ordnance survey
shp/os/strtgi_essh_gb/%.shp: os/strtgi_essh_gb.zip
	mkdir -p shp/$(basename $<) && unzip -u $< -d shp/$(basename $<)
	touch $@

topo/os/strtgi_essh_gb/data/%.topo.json: topo/os/strtgi_essh_gb/data/%.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

# Meridian 2 data from Ordnance survey
shp/os/merid2_essh_gb/%.shp: os/merid2_essh_gb.zip
	mkdir -p shp/$(basename $<) && unzip -u $< -d shp/$(basename $<)
	touch $@

topo/os/merid2_essh_gb/data/%.topo.json: topo/os/merid2_essh_gb/data/%.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

# Terrain 50 (height) data from Ordnance survey
shp/os/terr50_cesh_gb/%.shp: os/terr50_cesh_gb.zip
	mkdir -p shp/$(basename $<) && unzip -u $< -d shp/$(basename $<)
	touch $@

# Ordnance survey data manager and shapefile -> geojson converter.
os/%.zip: 
	mkdir -p $(dir $@); \
	echo "What is the full path of the directory where the $(notdir $@) file is found?"; \
	read path; \
	echo "Copying $(notdir $@) to $(dir $@)"; \
	cp -pr $$path/$(notdir $@) $(dir $@)
	touch $@

topo/os/%.json: shp/os/%.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<)
	mv $(dir $<)/$(notdir $@) $@


# Share geo (ONS) Strategic Health Authorities (England), Primary Care Organisations (England), Local Health Boards (Wales)
gz/sharegeo/Health%20Authority%20Boundaries%20for%20England%20and%20Wales.zip: 
	mkdir -p $(dir $@) && wget $(SHAREGEO)/10672/333/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/sharegeo/MYDATA_121312/%.shp: gz/sharegeo/Health%20Authority%20Boundaries%20for%20England%20and%20Wales.zip
	rm -rf $(dir $@) && mkdir -p $(dir $@) && unzip -u $< -d shp/sharegeo
	touch $(dir $@)/*

topo/sharegeo/MYDATA_121312/%.topo.json: topo/sharegeo/MYDATA_121312/%.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

topo/sharegeo/MYDATA_121312/%.json: shp/sharegeo/MYDATA_121312/%.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<)
	mv $(dir $<)/$(notdir $@) $@

# Sharegeo Green Belt.
gz/sharegeo/Green%20Belt%20England%202011.zip: 
	mkdir -p $(dir $@) && wget $(SHAREGEO)/10672/325/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/sharegeo/GreenBelt2011.shp: gz/sharegeo/Green%20Belt%20England%202011.zip
	mkdir -p $(dir $@) && unzip -u $< -d $(dir $@)
	touch $(dir $@)/*

topo/sharegeo/%.json: shp/sharegeo/%.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<)
	mv $(dir $<)/$(notdir $@) $@

topo/sharegeo/GreenBelt2011.topo.json: topo/sharegeo/GreenBelt2011.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

# Sharegeo Police areas (Geocommons)
gz/sharegeo/UK%20Police%20Force%20areas.zip: 
	mkdir -p $(dir $@) && wget $(SHAREGEO)/10672/328/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/sharegeo/uk_police_force_areas.shp: gz/sharegeo/UK%20Police%20Force%20areas.zip
	mkdir -p $(dir $@) && unzip -u $< -d $(dir $@)
	touch $(dir $@)/*

topo/sharegeo/uk_police_force_areas.json: shp/sharegeo/uk_police_force_areas.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<)
	mv $(dir $<)/$(notdir $@) $@

topo/sharegeo/uk_police_force_areas.topo.json: topo/sharegeo/uk_police_force_areas.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

# Sharegeo UK Fire Service Areas
gz/sharegeo/UK%20Fire%20Service%20Areas.zip: 
	mkdir -p $(dir $@) && wget $(SHAREGEO)/10672/368/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

shp/sharegeo/Fire_Services_Areas/fire_service_areas.shp: gz/sharegeo/UK%20Fire%20Service%20Areas.zip
	mkdir -p $(dir $@) && unzip -u $< -d shp/sharegeo && mv shp/sharegeo/Fire\ Service\ Areas $(dir $@)
	touch $(dir $@)/*

topo/sharegeo/fire_service_areas.json: shp/sharegeo/Fire_Services_Areas/fire_service_areas.shp
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-f GEOJSON \
		$(notdir $@) \
		$(notdir $<)
	mv $(dir $<)/$(notdir $@) $@

topo/sharegeo/fire_service_areas.topo.json: topo/sharegeo/fire_service_areas.json
	mkdir -p $(dir $@)
	topojson \
		-o $@ \
		$< \
		--properties \
		--simplify-proportion 0.2

# OSM extract of London from metro.teczno.com (Extractotron)
pbf/extractotron/london.osm.pbf: 
	mkdir -p $(dir $@) && wget $(EXTRACTOTRON)/$(notdir $@) -O $@.download && mv $@.download $@
	touch $@

topo/extractotron/london.osm.json: pbf/extractotron/london.osm.pbf
	mkdir -p $(dir $@)
	cd $(dir $<); \
	ogr2ogr \
		-f GeoJSON \
		$(notdir $@) \
		$(notdir $<)
	mv $< $@

# OSM Planet Coastline data
bz2/osm/processed_p.tar.bz2:
	mkdir -p $(dir $@) &&  wget $(OSMPLANET)/historical-shapefiles/processed_p.tar.bz2 -O $@.download && mv $@.download $@
	touch $@

# tar jxvf bz2/osm/processed_p.tar.bz2


