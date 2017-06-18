# tulip2json
# 5May2017 - SSP - created

# at some point i'll figure out how to make functions/plugins
# but for now you'll need the command line
# click the [3 Python] button on the bottom of the toolbar

# update this variable with filepath and filename (including .json)
outputFile = "C:\...\c207.json"

# then paste this into the command line
params = tlp.getDefaultPluginParameters('JSON Export', graph)
# params['Beautify JSON string'] = 1
success = tlp.exportGraph('JSON Export', graph, outputFile, params)
