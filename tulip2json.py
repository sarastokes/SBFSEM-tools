# tulip2json
# 5May2017 - SSP - created

# Tulip: http://chip.de/downloads/Tulip-64-Bit_41528289.html
# click the [3 Python] button on the bottom of the toolbar to open the command line

# update this variable with filepath and filename (including .json)
outputFile = "C:\...\filename.json"

# then paste this into the command line
params = tlp.getDefaultPluginParameters('JSON Export', graph)
success = tlp.exportGraph('JSON Export', graph, outputFile, params)

