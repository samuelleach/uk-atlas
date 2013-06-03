# This is a Makefile for producing the uk.json topojson file used in
# Mike Bostock's tutorial "Let's make a map" http://bost.ocks.org/mike/map/

# 3 June 2013: Now includes processing of Office of National
#              Statistics 2011 Ward boundaries. Thanks to John Nance
#              for help with ogr2ogr.

NATURALEARTH=http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural
ONS=http://data.statistics.gov.uk/ONSGeography/CensusGeography/Boundaries/2011

all: topo/uk.json \
	topo/ukwards.topo.json

clean:
	rm -rf gz shp topo ons

tidy:
	rm -rf *.README.html *.VERSION.txt *.prj

gz/%.zip:
	mkdir -p $(dir $@) && wget $(NATURALEARTH)/$(notdir $@) -O $@.download && mv $@.download $@

#Note that ogr2ogr requires the .shp, .shx and .dbf files to work.
shp/%.shp: gz/%.zip
	mkdir -p $(dir $@) && unzip $< && mv *.shp $(dir $@) && mv *.shx $(dir $@) && mv *.dbf $(dir $@) && mv *.prj $(dir $@)
	touch $@
	make tidy

topo/subunits.json: shp/ne_10m_admin_0_map_subunits.shp
	mkdir -p $(dir $@)
	cd shp; \
	ogr2ogr \
		-f GeoJSON \
		-where "adm0_a3 IN ('GBR', 'IRL')" \
		subunits.json \
		ne_10m_admin_0_map_subunits.shp; \
	mv $(notdir $@) ../$@
	
topo/places.json: shp/ne_10m_populated_places.shp
	mkdir -p $(dir $@)
	cd shp; \
	ogr2ogr \
		-f GeoJSON \
		-where "iso_a2 = 'GB' AND SCALERANK < 8" \
		places.json \
		ne_10m_populated_places.shp; \
	mv $(notdir $@) ../$@	

topo/uk.json: topo/subunits.json topo/places.json
	mkdir -p $(dir $@)
	topojson \
		--id-property su_a3 \
		-p name=NAME \
		-p name \
		-o topo/uk.json \
		topo/subunits.json \
		topo/places.json

ons/WD_DEC_2011_EW_BGC_shp.zip: 
	mkdir -p $(dir $@) && wget $(ONS)/Wards/$(notdir $@) -O $@.download && mv $@.download $@

shp/ons/WD_DEC_2011_EW_BGC.shp: ons/WD_DEC_2011_EW_BGC_shp.zip
	mkdir -p $(dir $@) && unzip $< -d $(dir $@)
	touch $@

topo/ukwards.json: shp/ons/WD_DEC_2011_EW_BGC.shp
	mkdir -p $(dir $@)
	cd shp/ons; \
	ogr2ogr \
		-t_srs "EPSG:4326" \
		-f GEOJSON \
		ukwards.json \
		WD_DEC_2011_EW_BGC.shp; \
	mv $(notdir $@) ../../$@

topo/ukwards.topo.json: topo/ukwards.json
	mkdir -p $(dir $@)
	topojson \
		-o topo/ukwards.topo.json \
		topo/ukwards.json \
		--id-property WD11CD \
		--properties WD11NM \
		--simplify-proportion 0.5

