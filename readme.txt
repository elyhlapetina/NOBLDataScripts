@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Author: Elyh Lapetina               @
@ Date: 4/10/2018                     @
@ Rev: 2.0                            @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Description:
The scripts contained in the CBCTCalibrationCode folder is used to calibrate sets of DiCOM files taken from dental CBCT machines. 
_____
GUI: 
StandardCalc.m:
This is the main entry point for the script. In order to run the script, open this file in Matlab and click run. Once the script is open, it will as the user to select the directory of DiCOM files the user's local disk. 

The user can scan through the DiCOM slides by dragging the slider at the bottom of the UI. The user may change views as desired by clicking any of the view buttons. 


CALIBRATION:
In order to calibrate the images using the standards, user should adjust the slider until all three (or four) standards are visible in the viewer, then the user should hit "mark 1" to tell the program this is the first slice of interest. Then the user should adjust the slider until the last slice where all three (or four) standard are visible. The user should then click "mark 2." The user is now ready to start the calibration process, the user should click "Calibrate Using Standards." The program will then verify the first and last slices have been selected. For each of the three (or four standards) the program will provide a cursor for Region of Interest selection. The following process will be repeated for each of the three (or four) standards. STARTING WITH THE LEAST DENSE STANDARD, the first click will zoom in on the region of interest, while the second click will select the center of the area. The viewer will then move to the slice that was selected with "mark 2" command. After the region of interests are selected for the least dense standard, Matlab will prompt the user to enter a radius to be used for selecting region of interest. The user will then be prompted to click to zoom, then click to select. Once this process has been completed for each standard, the program will show the user a sample rescale slope and intercept plot using the average values along with grayscale distributions for each standard. If this is acceptable, the user may op to continue with the calibration process or restart. By continuing, Matlab will activate a parallel processing command, generate gassing distributions based on the grayscale values for each standard, and calculate 100,000 different rescale slopes and intercepts. These values will be saved and must be used when taking measurements with distributions. 

MEASUREMENTS
The user may take a measurement by clicking the take measurement button. Before this is done, the user must select the first and last slide to average over. This is done by clicking "Mark 1" and "Mark 2". Once this is one, the UI will flip to the first "Mark" and allow the user to  select the center of the first circle to be average. The UI will then put the second "marked" slide into the view, the user will then select the center of the second circle. Once marked, the script will prompt the user to enter the radius of the circle.


SUBSCRIPTS:
_____
DICOM2Volumn.m:
This script iterates through each  DiCOM file and constructs an array that contains directory of each format in an ordered fashion.

_____

Generate3dMatrixCBCT.m:
This script takes input from the DICOM2Volume script and constructs a three-dimensional array where each index represents a voxel and contains the grayscale value of the represented voxel.
_____
CircularAVG.m:
This script returns the average value pixel for the area of pixels defined by an X,Y and R location. This function averages values based on a given radius, all values within the radius will be averaged. 

_____
ModelView.m:
The purpose of this function is to allow the user to visual a region of interest in three-dimensions. This script takes a three-dimensional array which is used to generate Matlab Isocaps. The user may adjust what values of Grayscale values are in view by adjusting the slider at the bottom of the UI.

_____
StandardCalc.m:
This is a standalone script that enables the user to easily calculate the predicted HU of HaPe standards based on percent-mass and the effective energy of the scanner. 



