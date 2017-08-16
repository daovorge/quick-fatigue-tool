#PYTHON SCRIPT FOR THE QUICK FATIGUE TOOL ODB INTERFACE
#
#   Find surface elements and nodes from an Abaqus ODB file.
#
#   Author contact:
#
#   M.Sc. Louis Vallance
#   louisvallance@hotmail.co.uk
#
#   Quick Fatigue Tool 6.11-02 Copyright Louis Vallance 2017
#   Last modified 16-Aug-2017 13:32:18 GMT

import os
from odbAccess import *
import odbAccess
from abaqusConstants import *
import string
from operator import itemgetter
from collections import Counter

"""
BEGIN USER INPUT
"""

# Abaqus ODB File:
ODB_NAME = '*.odb'

# Part instances:
PART_INSTANCES = 'ALL'
# Specify individual part instances like this:
# PART_INSTANCES = ['Instance-1', 'Instance-2',..., 'Instance-n']

# Treat shell surface as shell faces:
SHELL_FACES = 'NO'

# Create element set(s) from surface nodes:
ELEMENT_SET = 'NO'

# Write surface element/node sets to ODB:
SET_TO_ODB = 'YES'

# Write surface node set to text file:
SET_TO_TEXT = 'YES'

"""
END USER INPUT
"""

# Open ODB file:
odb = openOdb(path = ODB_NAME)

# Analyse all part instance:
if (PART_INSTANCES.lower() == 'all'):
	# Initialize indexing variable for part instance names:
	index = 0
	
	# Get number of part instances:
	nInstances = len(odb.rootAssembly.instances)
	
	# Initialize list containing part instance names:
	PART_INSTANCES = [0 for x in range(nInstances)]
	
	# Collect part instance names:
	for i in range(nInstances):
		currentInstance = odb.rootAssembly.instances.values()[i].name
		if (currentInstance != 'ASSEMBLY'):
			PART_INSTANCES[index] = currentInstance
			index = index + 1
		else:
			nInstances = nInstances - 1
else:
	# Get number of part instances:
	nInstances = len(PART_INSTANCES)

# Initialize part instance list:
instanceList = []

# Initialize list containing all surface nodes and elements:
surfaceNodesAll = [[0 for x in range(2)] for y in range(2)]
surfaceElementsAll = [[0 for x in range(2)] for y in range(2)]

# Loop over each part instance to find surface:
for instanceNumber in range(nInstances):
	# Get ODB part instance:
	partInstance = PART_INSTANCES[instanceNumber]
	instance = odb.rootAssembly.instances[partInstance]
	
	# Get number of elements belonging to part instance:
	N = len(instance.elements)
	
	# Initialize list containing all element faces (maximum 8 nodes per element face, 6*N element faces):
	faces = [[0 for x in range(8)] for y in range(6*N)]
	
	# Initialize indexing variable for element face data:
	index = 0
	
	for i in range(N):
		# Get element object:
		element = instance.elements[i]
		
		# Get element connectivity data:
		conn = instance.getElementFromLabel(element.label).connectivity
		
		# 3D continuum hexahedron (brick) elements:
		if ((element.type == 'C3D8') or (element.type == 'C3D8H') or (element.type == 'C3D8I') or (element.type == 'C3D8IH') or (element.type == 'C3D8R') or (element.type == 'C3D8RH') or (element.type == 'C3D8S') or (element.type == 'C3D8HS') or (element.type == 'C3D20') or (element.type == 'C3D20H') or (element.type == 'C3D20R') or (element.type == 'C3D20RH') or (element.type == 'C3D8T') or (element.type == 'C3D8HT') or (element.type == 'C3D8RT') or (element.type == 'C3D8RHT') or (element.type == 'C3D20T') or (element.type == 'C3D20HT') or (element.type == 'C3D20RT') or (element.type == 'C3D20RHT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Linear:
			if (len(conn) == 8):
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
				faces[index + 1][:] = itemgetter(*[4, 7, 6, 5])(conn)
				faces[index + 2][:] = itemgetter(*[0, 4, 5, 1])(conn)
				faces[index + 3][:] = itemgetter(*[1, 5, 6, 2])(conn)
				faces[index + 4][:] = itemgetter(*[2, 6, 7, 3])(conn)
				faces[index + 5][:] = itemgetter(*[3, 7, 4, 0])(conn)
				
			# Quadratic:
			else:
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 8, 9, 10, 11])(conn)
				faces[index + 1][:] = itemgetter(*[4, 7, 6, 5, 15, 14, 13, 12])(conn)
				faces[index + 2][:] = itemgetter(*[0, 4, 5, 1, 16, 12, 17, 8])(conn)
				faces[index + 3][:] = itemgetter(*[1, 5, 6, 2, 17, 13, 18, 9])(conn)
				faces[index + 4][:] = itemgetter(*[2, 6, 7, 3, 18, 14, 19, 10])(conn)
				faces[index + 5][:] = itemgetter(*[3, 7, 4, 0, 19, 15, 16, 11])(conn)
			
			indexIncrement = 6
			
		# 3D continuum tetrahedral elements:
		elif ((element.type == 'C3D4') or (element.type == 'C3D4H') or (element.type == 'C3D10') or (element.type == 'C3D10H') or (element.type == 'C3D10HS') or (element.type == 'C3D10M') or (element.type == 'C3D10MH') or (element.type == 'C3D4T') or (element.type == 'C3D10T') or (element.type == 'C3D10HT') or (element.type == 'C3D10MT') or (element.type == 'C3D10MHT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Linear:
			if (len(conn) == 4):
				faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
				faces[index + 1][:] = itemgetter(*[0, 3, 1])(conn)
				faces[index + 2][:] = itemgetter(*[1, 3, 2])(conn)
				faces[index + 3][:] = itemgetter(*[2, 3, 0])(conn)
				
			# Quadratic:
			else:
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 4, 5, 6])(conn)
				faces[index + 1][:] = itemgetter(*[0, 3, 1, 7, 8, 4])(conn)
				faces[index + 2][:] = itemgetter(*[1, 3, 2, 8, 9, 5])(conn)
				faces[index + 3][:] = itemgetter(*[2, 3, 0, 9, 7, 6])(conn)
			
			indexIncrement = 4
			
		# 3D continuum wedge (triangular prism) elements:
		elif ((element.type == 'C3D6') or (element.type == 'C3D6H') or (element.type == 'C3D15') or (element.type == 'C3D15H')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Linear:
			if (len(conn) == 6):
				faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
				faces[index + 1][:] = itemgetter(*[3, 5, 4])(conn)
				faces[index + 2][:] = itemgetter(*[0, 3, 4, 1])(conn)
				faces[index + 3][:] = itemgetter(*[1, 4, 5, 2])(conn)
				faces[index + 4][:] = itemgetter(*[2, 5, 3, 0])(conn)
				
			# Quadratic:
			else:
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 6, 7, 8])(conn)
				faces[index + 1][:] = itemgetter(*[3, 5, 4, 11, 10, 9])(conn)
				faces[index + 2][:] = itemgetter(*[0, 3, 4, 1, 12, 9, 13, 6])(conn)
				faces[index + 3][:] = itemgetter(*[1, 4, 5, 2, 13, 10, 14, 7])(conn)
				faces[index + 4][:] = itemgetter(*[2, 5, 3, 0, 14, 11, 12, 8])(conn)
			
			indexIncrement = 5
			
		# 3D continuum pyramid elements:
		elif ((element.type == 'C3D5') or (element.type == 'C3D5H')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
			faces[index + 1][:] = itemgetter(*[0, 4 , 1])(conn)
			faces[index + 2][:] = itemgetter(*[1, 4, 2])(conn)
			faces[index + 3][:] = itemgetter(*[2, 4, 3])(conn)
			faces[index + 4][:] = itemgetter(*[3, 4, 0])(conn)
			
			indexIncrement = 5
			
		# 3D conventional triangular shell elements:
		elif ((element.type == 'STRI3') or (element.type == 'S3') or (element.type == 'S3R') or (element.type == 'S3RS') or (element.type == 'STRI65') or (element.type == 'S3T') or (element.type == 'S3RT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Treat shell surface as shell faces:
			if (SHELL_FACES.lower() == 'yes'):
				
				# Linear:
				if (len(conn) == 3):
					faces[index + 0][:] = itemgetter(*[0, 1])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 3])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 4])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0, 5])(conn)
					
				indexIncrement = 3
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 3.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5])(conn)
				
				indexIncrement = 1
			
		# 3D conventional quadrilateral shell elements:
		elif ((element.type == 'S4') or (element.type == 'S4R') or (element.type == 'S4RS') or (element.type == 'S4RSW') or (element.type == 'S4R5') or (element.type == 'S8R') or (element.type == 'S8R5') or (element.type == 'S4T') or (element.type == 'S4RT') or (element.type == 'S8RT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Treat shell surface as shell faces:
			if (SHELL_FACES.lower() == 'yes'):
				
				# Linear:
				if (len(conn) == 4):
					faces[index + 0][:] = itemgetter(*[0, 1])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 4])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 5])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3, 6])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0, 7])(conn)
					
				indexIncrement = 4
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5, 6, 7])(conn)
				
				indexIncrement = 1
				
		# 3D continuum triangular shell elements:
		elif ((element.type == 'SC6R') or (element.type == 'SC6RT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
			faces[index + 1][:] = itemgetter(*[3, 5, 4])(conn)
			faces[index + 2][:] = itemgetter(*[0, 3, 4, 1])(conn)
			faces[index + 3][:] = itemgetter(*[1, 4, 5, 2])(conn)
			faces[index + 4][:] = itemgetter(*[2, 5, 3, 0])(conn)
			
			indexIncrement = 5
			
		# 3D continuum hexahedral shell elements:
		elif ((element.type == 'SC8R') or (element.type == 'SC8RT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
			faces[index + 1][:] = itemgetter(*[4, 7, 6, 5])(conn)
			faces[index + 2][:] = itemgetter(*[0, 4, 5, 1])(conn)
			faces[index + 3][:] = itemgetter(*[1, 5, 6, 2])(conn)
			faces[index + 4][:] = itemgetter(*[2, 6, 7, 3])(conn)
			faces[index + 5][:] = itemgetter(*[3, 7, 4, 0])(conn)
			
			indexIncrement = 6
			
		# 2D Continuum triangular elements:
		elif ((element.type == 'CPE3') or (element.type == 'CPE3H') or (element.type == 'CPE6') or (element.type == 'CPE6H') or (element.type == 'CPE6M') or (element.type == 'CPE6MH') or (element.type == 'CPS3') or (element.type == 'CPS6') or (element.type == 'CPS6M') or (element.type == 'CPEG3') or (element.type == 'CPEG3H') or (element.type == 'CPEG6') or (element.type == 'CPEG6H') or (element.type == 'CPEG6M') or (element.type == 'CPEG6MH')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Treat shell surface as shell faces:
			if (SHELL_FACES.lower() == 'yes'):
				
				# Linear:
				if (len(conn) == 3):
					faces[index + 0][:] = itemgetter(*[0, 1])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 3])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 4])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0, 5])(conn)
					
				indexIncrement = 3
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5])(conn)
				
				indexIncrement = 1
			
		# 2D Continuum quadrilateral elements:
		elif ((element.type == 'CPE4') or (element.type == 'CPE4H') or (element.type == 'CPE4I') or (element.type == 'CPE4IH') or (element.type == 'CPE4R') or (element.type == 'CPE4RH') or (element.type == 'CPE8') or (element.type == 'CPE8H') or (element.type == 'CPE8R') or (element.type == 'CPE8RH') or (element.type == 'CPS4') or (element.type == 'CPS4I') or (element.type == 'CPS4R') or (element.type == 'CPS8') or (element.type == 'CPS8R') or (element.type == 'CPEG4') or (element.type == 'CPEG4H') or (element.type == 'CPEG4I') or (element.type == 'CPEG4IH') or (element.type == 'CPEG4R') or (element.type == 'CPEG4RH') or (element.type == 'CPEG8') or (element.type == 'CPEG8H') or (element.type == 'CPEG8R') or (element.type == 'CPEG8RH')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			# Treat shell surface as shell faces:
			if (SHELL_FACES.lower() == 'yes'):
				
				# Linear:
				if (len(conn) == 4):
					faces[index + 0][:] = itemgetter(*[0, 1])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 4])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 5])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3, 6])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0, 7])(conn)
					
				indexIncrement = 4
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5, 6, 7])(conn)
				
				indexIncrement = 1
	
	# Use code template under FALSE if order matters:
	if False:
		z1 = [[1, 2, 3], [4, 5, 6], [2, 3, 1], [2, 5, 1]]
		
		def test(sublist, list_):
			for sub in list_:
				if all(x in sub for x in sublist):
					return False
			return True
		
		z2 = [x for i, x in enumerate(z1) if test(x, z1[:i] + z1[i+1:])]
		print(z2)  # This would output [[4, 5, 6], [2, 5, 1]]
	
	# Get surface nodes from unique faces:
	surfaceNodes = Counter([tuple(sorted(x)) for x in faces])
	surfaceNodes = [list(k) for k, v in surfaceNodes.items() if v == 1]
	
	# Flatten node set into iterable list:
	surfaceNodes = list(set(i for j in surfaceNodes for i in j))
	
	# Create node/element sets from surface nodes:
	if (SET_TO_ODB.lower() == 'yes'):
		
		# Create node set from surface nodes:
		setName = "Node-Surface-%s" % partInstance
		nodeSet = odb.rootAssembly.NodeSetFromNodeLabels(name = setName, nodeLabels = ((partInstance, surfaceNodes),))
		
		# Create element set from surface nodes:
		if (ELEMENT_SET.lower() == 'yes'):
			surfaceElements = []
			
			for j in range(N):
				# Get element connectivity data:
				element = instance.elements[j]
				conn = instance.getElementFromLabel(element.label).connectivity
				
				# Get intersection of connectivity with surface node list:
				intersect = [i for i in surfaceNodes if i in conn]
				
				# Check if there are any intersecting nodes:
				if (len(intersect) != 0):
					# Element j lies on surface, so append element:
					surfaceElements.append(element.label)
					
			# Create element set:
			setName = "Element-Surface-%s" % partInstance
			elementSet = odb.rootAssembly.ElementSetFromElementLabels(name = setName, elementLabels = ((partInstance, surfaceElements),))
			
			# Add current node set to global surface node set:
			surfaceElementsAll[instanceNumber][:] = surfaceElements
			
	# Add current part instance name to list:
	instanceList.append(partInstance)
	
	# Add current node set to global surface node set:
	surfaceNodesAll[instanceNumber][:] = surfaceNodes
	
	# Update user via Abaqus/CAE command window:
	print ("Instance '%s' contains %.0f nodes on the surface") % (partInstance, len(surfaceNodes))

if (SET_TO_ODB.lower() == 'yes'):
	# Create node set containing entire surface:
	setName = "Node-Surface-Whole"
	nodeLabelData = []
	for i in range(nInstances):
		nodeLabelData.append([instanceList[i], surfaceNodesAll[i]])

	nodeSet = odb.rootAssembly.NodeSetFromNodeLabels(name = setName, nodeLabels = nodeLabelData)

	# Create element set containing entire surface:
	if (ELEMENT_SET.lower() == 'yes'):
		setName = "Element-Surface-Whole"
		elementLabelData = []
		for i in range(nInstances):
			elementLabelData.append([instanceList[i], surfaceElementsAll[i]])
			
		elementSet = odb.rootAssembly.ElementSetFromElementLabels(name = setName, elementLabels = elementLabelData)
		
# Write surface node set to text file:
if (SET_TO_TEXT.lower() == 'yes'):
	for i in range(len(surfaceNodesAll) - 1):
		nodesToFile = surfaceNodesAll[i] + surfaceNodesAll[i + 1]
		
	directory = "%s/surface_nodes.dat" % os.path.dirname(os.path.abspath("__file__"))
	f = open(directory, 'w+')
	string = '%s' % nodesToFile
	f.write(string)
	f.close()
	
# Save and close ODB:
odb.save()
odb.close()

print "Surface detection complete"