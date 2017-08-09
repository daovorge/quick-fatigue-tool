from odbAccess import *
import odbAccess
from abaqusConstants import *
import string
from operator import itemgetter
from collections import Counter

# Source ODB:
odb = openOdb(path='*.odb')

# Get the ODB instnace:
instance = odb.rootAssembly.instances['PART-1-1']

# Get the number of elements belonging to the part instance:
N = len(instance.elements)

# Initialize list containing all element faces (maximum 4 nodes per element face, 6*N element faces):
faces = [[0 for x in range(4)] for y in range(6*N)]

# Initialize the indexing variable for element face data
index = 0

for i in range(N):
	element = instance.elements[i]
	
	elementi = instance.getElementFromLabel(i + 1)
	conn = elementi.connectivity
	
	# 3D Continuum hexahedron (brick) elements:
	if (element.type == 'C3D8') or (element.type == 'C3D8H') or (element.type == 'C3D8I') or (element.type == 'C3D8IH') or (element.type == 'C3D8R') or (element.type == 'C3D8RH') or (element.type == 'C3D8S') or (element.type == 'C3D8HS') or (element.type == 'C3D20') or (element.type == 'C3D20H') or (element.type == 'C3D20R') or (element.type == 'C3D20RH') or (element.type == 'C3D8T') or (element.type == 'C3D8HT') or (element.type == 'C3D8RT') or (element.type == 'C3D8RHT') or (element.type == 'C3D20T') or (element.type == 'C3D20HT') or (element.type == 'C3D20RT') or (element.type == 'C3D20RHT'):
		
		if (i > 0):
			index = index + indexIncrement
		
		indices_face = [0, 1, 2, 3]
		faces[index + 0][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [4, 7, 6, 5]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [0, 4, 5, 1]
		faces[index + 2][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [1, 5, 6, 2]
		faces[index + 3][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [2, 6, 7, 3]
		faces[index + 4][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [3, 7, 4, 0]
		faces[index + 5][:] = itemgetter(*indices_face)(conn)
		
		indexIncrement = 6
		
	# 3D Continuum tetrahedral elements:
	elif (element.type == 'C3D4') or (element.type == 'C3D4H') or (element.type == 'C3D10') or (element.type == 'C3D10H') or (element.type == 'C3D10HS') or (element.type == 'C3D10M') or (element.type == 'C3D10MH') or (element.type == 'C3D4T') or (element.type == 'C3D10T') or (element.type == 'C3D10HT') or (element.type == 'C3D10MT') or (element.type == 'C3D10MHT'):
		
		if (i > 0):
			index = index + indexIncrement
		
		indices_face = [0, 1, 2]
		faces[index + 0][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [0, 3, 1]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [1, 3, 2]
		faces[index + 2][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [2, 3, 0]
		faces[index + 3][:] = itemgetter(*indices_face)(conn)
		
		indexIncrement = 4
		
	# 3D Continuum wedge (triangular prism) elements:
	elif (element.type == 'C3D6') or (element.type == 'C3D6H') or (element.type == 'C3D15') or (element.type == 'C3D15H'):
		
		if (i > 0):
			index = index + indexIncrement
		
		indices_face = [0, 1, 2]
		faces[index + 0][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [3, 5, 4]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [0, 3, 4, 1]
		faces[index + 2][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [1, 4, 5, 2]
		faces[index + 3][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [2, 5, 3, 0]
		faces[index + 4][:] = itemgetter(*indices_face)(conn)
		
		indexIncrement = 5
		
	# 3D Continuum pyramid elements:
	elif (element.type == 'C3D5') or (element.type == 'C3D5H'):
		
		if (i > 0):
			index = index + indexIncrement
		
		indices_face = [0, 1, 2, 3]
		faces[index + 0][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [0, 4 , 1]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [1, 4, 2]
		faces[index + 2][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [2, 4, 3]
		faces[index + 3][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [3, 4, 0]
		faces[index + 4][:] = itemgetter(*indices_face)(conn)
		
		indexIncrement = 5
		
	# 2D Continuum triangular elements:
	elif (element.type == 'CPE3') or (element.type == 'CPE3H') or (element.type == 'CPE6') or (element.type == 'CPE6H') or (element.type == 'CPE6M') or (element.type == 'CPE6MH') or (element.type == 'CPS3') or (element.type == 'CPS6') or (element.type == 'CPS6M') or (element.type == 'CPEG3') or (element.type == 'CPEG3H') or (element.type == 'CPEG6') or (element.type == 'CPEG6H') or (element.type == 'CPEG6M') or (element.type == 'CPEG6MH'):
		
		if (i > 0):
			index = index + indexIncrement
		
		indices_face = [0, 1]
		faces[index + 0][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [1, 2]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [2, 0]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indexIncrement = 3
		
	# 2D Continuum quadrilateral elements:
	elif (element.type == 'CPE4') or (element.type == 'CPE4H') or (element.type == 'CPE4I') or (element.type == 'CPE4IH') or (element.type == 'CPE4R') or (element.type == 'CPE4RH') or (element.type == 'CPE8') or (element.type == 'CPE8H') or (element.type == 'CPE8R') or (element.type == 'CPE8RH') or (element.type == 'CPS4') or (element.type == 'CPS4I') or (element.type == 'CPS4R') or (element.type == 'CPS8') or (element.type == 'CPS8R') or (element.type == 'CPEG4') or (element.type == 'CPEG4H') or (element.type == 'CPEG4I') or (element.type == 'CPEG4IH') or (element.type == 'CPEG4R') or (element.type == 'CPEG4RH') or (element.type == 'CPEG8') or (element.type == 'CPEG8H') or (element.type == 'CPEG8R') or (element.type == 'CPEG8RH'):
		
		if (i > 0):
			index = index + indexIncrement
		
		indices_face = [0, 1]
		faces[index + 0][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [1, 2]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [2, 3]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indices_face = [3, 0]
		faces[index + 1][:] = itemgetter(*indices_face)(conn)
		
		indexIncrement = 4

print faces

# IF THE ORDER MATTERS
#z1 = [[1, 2, 3], [4, 5, 6], [2, 3, 1], [2, 5, 1]]
#
#def test(sublist, list_):
#    for sub in list_:
#        if all(x in sub for x in sublist):
#            return False
#    return True
#
#z2 = [x for i, x in enumerate(z1) if test(x, z1[:i] + z1[i+1:])]
#print(z2)  # [[4, 5, 6], [2, 5, 1]]

# Get unique faces:
uniqueNodes = Counter([tuple(sorted(x)) for x in faces])
uniqueNodes = [list(k) for k, v in uniqueNodes.items() if v == 1]

# Flatten the node into a set
uniqueNodes = set(i for j in uniqueNodes for i in j)

# Create a node set from the free element faces:
nodeSet = odb.rootAssembly.NodeSetFromNodeLabels(name='Node-Surface', nodeLabels=(('PART-1-1', list(uniqueNodes)),))

# Save and close the ODB:
odb.save()
odb.close()