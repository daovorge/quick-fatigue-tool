#PYTHON SCRIPT FOR THE QUICK FATIGUE TOOL ODB INTERFACE
#
#   Get stress components from an Abaqus ODB file.
#
#   Author contact:
#
#   M.Sc. Louis Vallance
#   louisvallance@hotmail.co.uk
#
#   Quick Fatigue Tool 6.11-02 Copyright Louis Vallance 2017
#   Last modified 16-Aug-2017 10:28:46 GMT

from odbAccess import *
import odbAccess
from abaqusConstants import *
import string
from operator import itemgetter
from collections import Counter

# Abaqus ODB File:
odbName = 'E:/Project_Directories/abaqus/default/Job-1 - Copy.odb'

# Step name:
stepName = 'Step-1'

# Frame number:
frameNumber = 1

# Get the ODB object:
odb = openOdb(path = odbName)

# Get stress component:
S11 = odb.steps[stepName].frames[frameNumber].fieldOutputs['S'].getSubset(position = ELEMENT_NODAL).values[0].data[0]
S22 = odb.steps[stepName].frames[frameNumber].fieldOutputs['S'].getSubset(position = ELEMENT_NODAL).values[0].data[1]
S33 = odb.steps[stepName].frames[frameNumber].fieldOutputs['S'].getSubset(position = ELEMENT_NODAL).values[0].data[2]
S12 = odb.steps[stepName].frames[frameNumber].fieldOutputs['S'].getSubset(position = ELEMENT_NODAL).values[0].data[3]
S13 = odb.steps[stepName].frames[frameNumber].fieldOutputs['S'].getSubset(position = ELEMENT_NODAL).values[0].data[4]
S23 = odb.steps[stepName].frames[frameNumber].fieldOutputs['S'].getSubset(position = ELEMENT_NODAL).values[0].data[5]