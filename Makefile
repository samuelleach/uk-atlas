# This is a Makefile for producing the uk.json topojson file used in
# Mike Bostock's tutorial "Let's make a map" http://bost.ocks.org/mike/map/

NATURALEARTH=http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural

all: topo/uk.json

clean:
	rm -rf gz shp topo

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
		-p NAME=name \
		-p name \
		-o topo/uk.json \
		topo/subunits.json \
		topo/places.json