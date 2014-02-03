import osgeo.gdal, ogr
import sys

# Get info about a shapefile with
#
# ogrinfo -al -so myshapefile.shp
#
# Example:
# python bin/shape2area.py shp/ons/MSOA_2011_EW_BGC.shp MSOA11CD

shapefilename = sys.argv[1]
# print '# Data from ' + shapefilename
shapefile = osgeo.ogr.Open(shapefilename)

key = sys.argv[2]
# print '# key = ' + key

layer = shapefile.GetLayer(0)
numberFeatures = layer.GetFeatureCount()

keys = layer.GetFeature(0).keys()

if key in keys:
   print key + ',' + 'area'
   for i in range(numberFeatures):
      feature = layer.GetFeature(i)
      geometry = feature.GetGeometryRef()

      Area = geometry.GetArea()

      print feature.GetField(key) + ',' + str(Area) #, feature.GetFID()
else:
	print 'key not found: ' + key
	print 'Choose a key from ', keys