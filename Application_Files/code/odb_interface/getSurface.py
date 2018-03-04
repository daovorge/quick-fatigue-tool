#GETSURFACE Python script to extract the surface elements/nodes from an Abaqus ODB file.
#	<abaqus-id> python getSurface.py -- ODB_NAME POSITION SEARCH_REGION SHELL_FACES PART_INSTANCES
#   N_INSTANCES searches an Abaqus ODB file for the free surface at a given element position,
#   search region and part instance.
#
#   ODB_NAME: Full path to the output database file
#   POSITION: Element position
#   SEARCH_REGION: Search either the part instance or a list of element IDs
#   SHELL_FACES: Treat shell surface as whole shell or free shell faces
#   PART_INSTANCES: Part instance list
#   N_INSTANCES: Number of part instances
#
#	The script is called as follows:
#	<abaqus-id> python getSurface.py -- "\..\<model-name>.odb" {ELEMENTAL | NODAL | CENTROID}
#   {INSTANCE | DATASET} {YES | NO} "<part-instance-name>" <number-of-instances>
#
#	Example command line usage for a single part instance:
#	abaqus python getSurface.py -- "..\<file-name>.odb" ELEMENTAL INSTANCE NO "PART-1-1" 1
#
#	Example command line usage for N part instances:
#	abaqus python getSurface.py -- <preceding arguments> "PART-1-1" "PART-2-1" ... "PART-N-1" N
#
#	This surface detection algorithm relies on the principle
#	that, if the set of nodes of element face A does not have
#	a union with any other element face, then A belongs on
#	the element free surface.
#
#	Since the Abaqus Python APIs do not supply the node face
#	data for an element, the faces must be constructed manually
#	depending on the element family. The node ordering and face
#	numbering information was taken from "Part VI: Elements" of
#	the Abaqus Analysis User's Guide.
#
#   GETSURFACE.py is used internally by Quick Fatigue Tool. The user is not required to run this
#   file.
#
#   Reference section in Quick Fatigue Tool User Guide
#      4.5.3 Custom analysis items
#
#   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
#   Last modified 13-Feb-2018 20:14:48 GMT

import os
from odbAccess import *
import odbAccess
from abaqusConstants import *
import string
from operator import itemgetter
from collections import Counter
import sys

N_INSTANCES = int(sys.argv[-1])
PART_INSTANCES = []

for i in range(N_INSTANCES):
	PART_INSTANCES.append(sys.argv[-(i + 2)])
	
ODB_NAME = sys.argv[-5 - N_INSTANCES]
POSITION = sys.argv[-4 - N_INSTANCES]
SEARCH_REGION = sys.argv[-3 - N_INSTANCES]
SHELL_FACES = sys.argv[-2 - N_INSTANCES]

# Debug output:
print "ODB Name: %s" % ODB_NAME
print "Result position: %s" % POSITION
print "Search region: %s" % SEARCH_REGION
print "Shell faces: %s" % SHELL_FACES
print "Part instance: %s" % PART_INSTANCES
print "Number of instances: %s\n" % N_INSTANCES

# Open ODB file:
odb = openOdb(path = ODB_NAME)

# Get number of part instances:
nInstances = len(PART_INSTANCES)

# Initialize list containing all surface nodes and elements:
surfaceNodesAll = [[0 for x in range(2)] for y in range(nInstances)]
surfaceElementsAll = [[0 for x in range(2)] for y in range(nInstances)]
surfaceConnectingNodesAll = [[0 for x in range(2)] for y in range(nInstances)]

# Get the element IDs:
if (SEARCH_REGION.lower() == 'dataset'):
	directory = "%s/Application_Files/code/odb_interface/element_ids.dat" % os.path.dirname(os.path.abspath("__file__"))
	fid = open(directory, 'r')
	f = fid.read()
	ELEMENT_ID = f.split(',')
	fid.close()

# Initialize buffer containing any supported elements
unsupportedElements = []
	
# Loop over each part instance to find surface:
for instanceNumber in range(nInstances):
	# Get ODB part instance:
	partInstance = PART_INSTANCES[instanceNumber]
	instance = odb.rootAssembly.instances[partInstance]
	
	# Get number of elements belonging to part instance:
	if (SEARCH_REGION.lower() == 'dataset'):
		N = len(ELEMENT_ID)
	else:
		N = len(instance.elements)
		
	# Initialize list containing all element faces (maximum 8 nodes per element face, 6*N element faces):
	faces = [[0 for x in range(8)] for y in range(6*N)]
	
	# Initialize indexing variable for element face data:
	index = 0
	
	# Container for existing element types (reset per instance iteration):
	tetAndHex = [0 for x in range(2)]
	
	# Container for existing element orders (reset per instance iteration):
	linearAndQuad = [0 for x in range(2)]
	
	for i in range(N):
		if (SEARCH_REGION.lower() == 'dataset'):
			# Get element object:
			element = instance.getElementFromLabel(int(ELEMENT_ID[i]))
			# Get element connectivity data:
			conn = element.connectivity
		else:
			# Get element object:
			element = instance.elements[i]
			# Get element connectivity data:
			conn = instance.getElementFromLabel(element.label).connectivity
			
		# ELTYPE 3D continuum hexahedron (brick) elements:
		if ((element.type == 'C3D8') or (element.type == 'C3D8H') or (element.type == 'C3D8I') or (element.type == 'C3D8IH') or (element.type == 'C3D8R') or (element.type == 'C3D8RH') or (element.type == 'C3D8S') or (element.type == 'C3D8HS') or (element.type == 'C3D20') or (element.type == 'C3D20H') or (element.type == 'C3D20R') or (element.type == 'C3D20RH') or (element.type == 'C3D8T') or (element.type == 'C3D8HT') or (element.type == 'C3D8RT') or (element.type == 'C3D8RHT') or (element.type == 'C3D20T') or (element.type == 'C3D20HT') or (element.type == 'C3D20RT') or (element.type == 'C3D20RHT') or (element.type == 'C3D8C3') or (element.type == 'C3D8IC3') or (element.type == 'C3D8RC3') or (element.type == 'C3D8HC3') or (element.type == 'C3D8RHC3') or (element.type == 'C3D8IHC3') or (element.type == 'C3D20C3') or (element.type == 'C3D20HC3') or (element.type == 'C3D20RC3') or (element.type == 'C3D20RHC3')):
			
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
				
				linearAndQuad[0] = 1
				
			# Quadratic:
			else:
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 8, 9, 10, 11])(conn)
				faces[index + 1][:] = itemgetter(*[4, 7, 6, 5, 15, 14, 13, 12])(conn)
				faces[index + 2][:] = itemgetter(*[0, 4, 5, 1, 16, 12, 17, 8])(conn)
				faces[index + 3][:] = itemgetter(*[1, 5, 6, 2, 17, 13, 18, 9])(conn)
				faces[index + 4][:] = itemgetter(*[2, 6, 7, 3, 18, 14, 19, 10])(conn)
				faces[index + 5][:] = itemgetter(*[3, 7, 4, 0, 19, 15, 16, 11])(conn)
				
				linearAndQuad[1] = 1
			
			indexIncrement = 6
			tetAndHex[1] = 1
			
		# ELTYPE 3D continuum tetrahedral elements:
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
				
				linearAndQuad[0] = 1
				
			# Quadratic:
			else:
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 4, 5, 6])(conn)
				faces[index + 1][:] = itemgetter(*[0, 3, 1, 7, 8, 4])(conn)
				faces[index + 2][:] = itemgetter(*[1, 3, 2, 8, 9, 5])(conn)
				faces[index + 3][:] = itemgetter(*[2, 3, 0, 9, 7, 6])(conn)
				
				linearAndQuad[1] = 1
			
			indexIncrement = 4
			tetAndHex[0] = 1
			
		# ELTYPE 3D continuum wedge (triangular prism) elements:
		elif ((element.type == 'C3D6') or (element.type == 'C3D6T') or (element.type == 'C3D6H') or (element.type == 'C3D15') or (element.type == 'C3D15H')):
			
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
				
				linearAndQuad[0] = 1
				
			# Quadratic:
			else:
				faces[index + 0][:] = itemgetter(*[0, 1, 2, 6, 7, 8])(conn)
				faces[index + 1][:] = itemgetter(*[3, 5, 4, 11, 10, 9])(conn)
				faces[index + 2][:] = itemgetter(*[0, 3, 4, 1, 12, 9, 13, 6])(conn)
				faces[index + 3][:] = itemgetter(*[1, 4, 5, 2, 13, 10, 14, 7])(conn)
				faces[index + 4][:] = itemgetter(*[2, 5, 3, 0, 14, 11, 12, 8])(conn)
				
				linearAndQuad[1] = 1
			
			indexIncrement = 5
			
		# ELTYPE 3D continuum pyramid elements:
		elif ((element.type == 'C3D5') or (element.type == 'C3D5H')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
			faces[index + 1][:] = itemgetter(*[0, 4 , 1])(conn)
			faces[index + 2][:] = itemgetter(*[1, 4, 2])(conn)
			faces[index + 3][:] = itemgetter(*[2, 4, 3])(conn)
			faces[index + 4][:] = itemgetter(*[3, 4, 0])(conn)
			
			linearAndQuad[0] = 1
			
			indexIncrement = 5
			
		# ELTYPE 3D conventional triangular shell elements:
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 3])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 4])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0, 5])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 3
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 3.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE 3D conventional quadrilateral shell elements:
		elif ((element.type == 'S4') or (element.type == 'S4R') or (element.type == 'S4RS') or (element.type == 'S4RSW') or (element.type == 'S4R5') or (element.type == 'S8R') or (element.type == 'S8R5') or (element.type == 'S4T') or (element.type == 'S4RT') or (element.type == 'S8RT') or (element.type == 'S9R5')):
			
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 4])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 5])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3, 6])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0, 7])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 4
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5, 6, 7])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE General triangular membrane elements:
		elif ((element.type == 'M3D3') or (element.type == 'M3D6')):
				
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 3])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 4])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0, 5])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 3
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 3.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE General quadrilateral membrane elements:
		elif ((element.type == 'M3D4') or (element.type == 'M3D4R') or (element.type == 'M3D8') or (element.type == 'M3D8R') or (element.type == 'M3D9') or (element.type == 'M3D9R')):
				
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 4])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 5])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3, 6])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0, 7])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 4
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5, 6, 7])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE 3D continuum triangular shell elements:
		elif ((element.type == 'SC6R') or (element.type == 'SC6RT')):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
			faces[index + 1][:] = itemgetter(*[3, 5, 4])(conn)
			faces[index + 2][:] = itemgetter(*[0, 3, 4, 1])(conn)
			faces[index + 3][:] = itemgetter(*[1, 4, 5, 2])(conn)
			faces[index + 4][:] = itemgetter(*[2, 5, 3, 0])(conn)
			
			linearAndQuad[0] = 1
			
			indexIncrement = 5
			
		# ELTYPE 3D continuum hexahedral shell elements:
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
			
			linearAndQuad[0] = 1
			
			indexIncrement = 6
			
		# ELTYPE 3D continuum solid hexahedral shell elements
		elif (element.type == 'CSS8'):
			
			# Increment INDEX face node variable:
			if (i > 0):
				index = index + indexIncrement
			
			faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
			faces[index + 1][:] = itemgetter(*[4, 7, 6, 5])(conn)
			faces[index + 2][:] = itemgetter(*[0, 4, 5, 1])(conn)
			faces[index + 3][:] = itemgetter(*[1, 5, 6, 2])(conn)
			faces[index + 4][:] = itemgetter(*[2, 6, 7, 3])(conn)
			faces[index + 5][:] = itemgetter(*[3, 7, 4, 0])(conn)
			
			linearAndQuad[0] = 1
			
			indexIncrement = 6
			
		# ELTYPE 2D continuum triangular elements:
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 3])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 4])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0, 5])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 3
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE 2D Continuum quadrilateral elements:
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 4])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 5])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3, 6])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0, 7])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 4
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5, 6, 7])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE Axisymmetric solid triangular elements:
		elif ((element.type == 'CAX3') or (element.type == 'CAX3H') or (element.type == 'CGAX3') or (element.type == 'CGAX3H') or (element.type == 'CAX3T') or (element.type == 'CGAX3T') or (element.type == 'CGAX3HT') or (element.type == 'CAX6') or (element.type == 'CAX6H') or (element.type == 'CAX6M') or (element.type == 'CAX6MH') or (element.type == 'CGAX6') or (element.type == 'CGAX6H') or (element.type == 'CGAX6M') or (element.type == 'CGAX6MH') or (element.type == 'CAX6MT') or (element.type == 'CAX6MHT') or (element.type == 'CGAX6MT') or (element.type == 'CGAX6MHT') or (element.type == 'CAX6MP') or (element.type == 'CAX6MPH')):
			
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 3])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 4])(conn)
					faces[index + 2][:] = itemgetter(*[2, 0, 5])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 3
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
				
		# ELTYPE Axisymmetric solid quadrilateral elements:
		elif ((element.type == 'CAX4') or (element.type == 'CAX4H') or (element.type == 'CAX4I') or (element.type == 'CAX4IH') or (element.type == 'CAX4R') or (element.type == 'CAX4RH') or (element.type == 'CGAX4') or (element.type == 'CGAX4H') or (element.type == 'CGAX4R') or (element.type == 'CGAX4RH') or (element.type == 'CAX4T') or (element.type == 'CAX4HT') or (element.type == 'CAX4RT') or (element.type == 'CAX4RHT') or (element.type == 'CGAX4T') or (element.type == 'CGAX4HT') or (element.type == 'CGAX4RT') or (element.type == 'CGAX4RHT') or (element.type == 'CAX4P') or (element.type == 'CAX4PH') or (element.type == 'CAX4RP') or (element.type == 'CAX4RPH') or (element.type == 'CAX4PT') or (element.type == 'CAX4RPT') or (element.type == 'CAX4RPHT') or (element.type == 'COHAX4') or (element.type == 'CAX8') or (element.type == 'CAX8H') or (element.type == 'CAX8R') or (element.type == 'CAX8RH') or (element.type == 'CGAX8') or (element.type == 'CGAX8H') or (element.type == 'CGAX8R') or (element.type == 'CGAX8RH') or (element.type == 'CAX8T') or (element.type == 'CAX8HT') or (element.type == 'CAX8RT') or (element.type == 'CAX8RHT') or (element.type == 'CGAX8T') or (element.type == 'CGAX8HT') or (element.type == 'CGAX8RT') or (element.type == 'CGAX8RHT') or (element.type == 'CAX8P') or (element.type == 'CAX8PH') or (element.type == 'CAX8RP') or (element.type == 'CAX8RPH')):
			
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
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 4])(conn)
					faces[index + 1][:] = itemgetter(*[1, 2, 5])(conn)
					faces[index + 2][:] = itemgetter(*[2, 3, 6])(conn)
					faces[index + 3][:] = itemgetter(*[3, 0, 7])(conn)
					
					linearAndQuad[1] = 1
					
				indexIncrement = 4
				
			# Treat shell surface as whole shell:
			else:
				
				# Linear:
				if (len(conn) == 4.0):
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3])(conn)
					
					linearAndQuad[0] = 1
					
				# Quadratic:
				else:
					faces[index + 0][:] = itemgetter(*[0, 1, 2, 3, 4, 5, 6, 7])(conn)
					
					linearAndQuad[1] = 1
				
				indexIncrement = 1
		else:
			# This element is not supported by the surface detection algorithm
			unsupportedElements.append(element.type)
			
	# Get surface nodes from unique faces:
	surfaceNodes = Counter([tuple(sorted(x)) for x in faces])
	surfaceNodes = [list(k) for k, v in surfaceNodes.items() if v == 1]
	
	# Flatten node set into iterable list:
	surfaceNodes = list(set(i for j in surfaceNodes for i in j))
	
	# Add current node set to global surface node set:
	surfaceNodesAll[instanceNumber][:] = surfaceNodes
	
	# Get surface elements from surface nodes:
	if (POSITION.lower() == 'elemental') or (POSITION.lower() == 'centroid'):
		surfaceElements = []
		surfaceConnectingNodes = []
		
		for j in range(N):
			if (SEARCH_REGION.lower() == 'dataset'):
				# Get element object:
				element = instance.getElementFromLabel(int(ELEMENT_ID[j]))
				# Get element connectivity data:
				conn = element.connectivity
			else:
				# Get element object:
				element = instance.elements[j]
				# Get element connectivity data:
				conn = instance.getElementFromLabel(element.label).connectivity
				
			# Get intersection of connectivity with surface node list:
			intersect = [i for i in surfaceNodes if i in conn]
			
			# Check if there are any intersecting nodes:
			if (len(intersect) != 0):
				# Element j lies on surface, so append element:
				surfaceElements.append(element.label)
				
				if (POSITION.lower() == 'elemental'):
					surfaceConnectingNodes.append(conn)
					
		# Add current node set to global surface element set:
		surfaceElementsAll[instanceNumber][:] = surfaceElements
		surfaceConnectingNodesAll[instanceNumber][:] = surfaceConnectingNodes
		
	# Check if there is an element shape incompatibility:
	if (tetAndHex[0] == 1 and tetAndHex[1] == 1):
		print "'%s' ELEM_INCOMPATIBLE" % partInstance
		
	# Check if there is a geometric order incompatibility:
	if (linearAndQuad[0] == 1 and linearAndQuad[1] == 1):
		print "'%s' GEOM_INCOMPATIBLE" % partInstance
		
# Write surface node set to text file:
if (POSITION.lower() == 'nodal'):
	if (nInstances == 1):
		nodesToFile = surfaceNodesAll[0]
	else:
		for i in range(len(surfaceNodesAll) - 1):
			nodesToFile = surfaceNodesAll[i] + surfaceNodesAll[i + 1]
			
	directory = "%s/Application_Files/code/odb_interface/surface_nodes.dat" % os.path.dirname(os.path.abspath("__file__"))
	f = open(directory, 'w+')
	string = '%s' % nodesToFile
	f.write(string)
	f.close()
elif (POSITION.lower() == 'elemental'):
	if (nInstances == 1):
		elementsToFile = surfaceElementsAll[0]
		nodesToFile = surfaceConnectingNodesAll[0]
	else:
		for i in range(len(surfaceElementsAll) - 1):
			elementsToFile = surfaceElementsAll[i] + surfaceElementsAll[i + 1]
			nodesToFile = surfaceConnectingNodesAll[i] + surfaceConnectingNodesAll[i + 1]
			
	directory = "%s/Application_Files/code/odb_interface/surface_elements.dat" % os.path.dirname(os.path.abspath("__file__"))
	f = open(directory, 'w+')
	string = '%s' % elementsToFile
	f.write(string)
	f.close()
	
	directory = "%s/Application_Files/code/odb_interface/surface_nodes.dat" % os.path.dirname(os.path.abspath("__file__"))
	f = open(directory, 'w+')
	string = '%s' % nodesToFile
	f.write(string)
	f.close()
elif (POSITION.lower() == 'centroid'):
	if (nInstances == 1):
		elementsToFile = surfaceElementsAll[0]
	else:
		for i in range(len(surfaceElementsAll) - 1):
			elementsToFile = surfaceElementsAll[i] + surfaceElementsAll[i + 1]
			
	directory = "%s/Application_Files/code/odb_interface/surface_elements.dat" % os.path.dirname(os.path.abspath("__file__"))
	f = open(directory, 'w+')
	string = '%s' % elementsToFile
	f.write(string)
	f.close()
	
# Close ODB:
odb.close()

print "Outcome: SUCCESS"
print "Unsupported elements: %s" % list(set(unsupportedElements))