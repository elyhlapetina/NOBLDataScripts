%% Last revised 07/05/18 - AL

function standardCalc

%This code actually changes the rescale slop and intercept for all slices.
%-- KV
clear global
close all
%Set all of your global variables. -- KV

global firstDir
firstDir = cd;

global activeMatSize
activeMatSize = 1;

%RS and RI is the rescale slope and rescale intercept for the linear
%calibration. RS and RI are obtained from the totalAverage variable. -- KV
global RS_lin 
global RI_lin 
global RS_exp
global RI_exp

%Intial and final slice of region of interest -EL
global mark1
global mark2

%coeffa coeffb are the rescale slopes for the exponential calibration using
%the equation coeffa(exp(coeffb*PV)). coeffa and coeffb are
%obtained using the totalAverage variable.
global coeffa
global coeffb

%ginfo1 is used here to store the dicominfo information for each slice in
%the Generate3dMatrix -- KV
global ginfo1

%Axis of view
global viewType
%Postion of slider viewer
global sliderPositon

mark1 = 1;
mark2 = 1;
RS_lin = [];
RI_lin = [];
RS_exp = [];
RI_exp = [];
coeffb = [];
coeffa = [];
n = 1;
measurementCount = 1;

cordinates3 = 0;
viewType = 1;
sliderPositon = 1;


[dirname] = uigetdir('Please choose dicom directory');
filetype = questdlg('Have you used this set of DiCOM files before?', 'Choose One', 'Yes', 'No', 'Cancel');
switch filetype
    case 'Yes'
        dataset = 2;
    case 'No'
        dataset = 1; 
end

if dataset == 1
    matrix = Generate3dMatrixCBCT(dirname);
    cd(dirname)
    save('PVmatrix.mat','matrix')
    save('ginfo.mat','ginfo1')
elseif dataset == 2
    cd(dirname)
    load('PVmatrix.mat')
    load('ginfo.mat')
    
end


%% UI CALLBACKS %%%%%%%%%%
    %% This function dynamically switches to Axial view
    function switchViewAxialCallback(hObject,event)
        viewType = 1;
        activeMatSize = 1;
        updateImage()
       
    end
    
    %% This function dynamically switches to Sagittal view
    function switchViewSagittalCallback(hObject, event)
        viewType = 2;
        activeMatSize = 2;
        updateImage()
    end

    %% This function dynamically switches to Coronal view
    function switchViewCoronalCallback(hObject, event)
        viewType = 3;
        activeMatSize = 3;
        updateImage()
    end


%% This function is updating the image we see as we scroll through the z slices -- KV
    function updateImageCallback(hObject,event)
        sliderPositon = uint16(get(hObject,'Value'));
        
        updateImage();
    end

%% This function is the callback for running the "take measurement" routine.
    function takeLineMeasurementCallback(hObject, event)
        takeLineMeasurement()
        
    end

%% This function is the callback for running the "take measurement" routine.
    function takeMeasurementCallback(hObject, event)
        %takeMeasurement()
        takeMeasurement()
        
    end

    function takeMeasurementWithDistCallback(hObject, event)
        takeMeasurementWithDist()
        
    end

%% This function is the callback for running the water air calibration 
    function initWaterAirCalibCallback(hObject,event)
        waterAirCalibration();
    end

%% This function is the callback for running the standard calibration

    function initStandardCalibrationCallback(hObject,event)        
        standardCalibration();
    end

%% This function is indicating the Z slice we choose for Mark1 -- KV
    function setmark1(hObject,event)
        mark1 = sliderPositon;
        set(btn1, 'string', strcat('Mark1: ',num2str(sliderPositon)));
    end
%% This function is indicating the Z slice we choose for Mark2 -- KV
    function setmark2(hObject,event)
        mark2 = sliderPositon;
        set(btn2, 'string', strcat('Mark2: ',num2str(sliderPositon)));
    end

%% inserting the x and y cordinates for the first and second point we choose to indicate the radius
 %cordinates1 is the center of the of the standard at Mark1. cordinates2
 %is the outer border of the standard. cordinates3 below is the
 %center of the of the standard at Mark2. -- KV
    function getradiusCallback(hObject,event)
        radius_coordinates1 = ginput(1)
        radius_coordinates2 = ginput(1)
        X1 = radius_coordinates1(1);
        Y1 = radius_coordinates1(2);
       
        X2 = radius_coordinates2(1);
        Y2 = radius_coordinates2(2);
        radius = sqrt((X2-X1)^2 + (Y2-Y1)^2)
        set(getRadius, 'string', strcat('Radius: ',num2str(radius)));
        
    end

%% getting the pixel value from the ginput -- KV
    function getpoint(hObject,event)
        cordinates3 = ginput(1);
        xvalue = cordinates3(1)
        yvalue = cordinates3(2)
        set(mark2Center, 'string', strcat('X= ', num2str(xvalue), 'Y= ',num2str(yvalue)))
        
    end

%% initiaizes 3d im view
    function threeDimensionalAnalysisCallback(hObject,event)
       
        cd(firstDir)
        %Defines the values in which model is viewable
        pixelRangeX = 40;
        pixexlRangeZ = 80;
        
        %Asks user to select point from image
        selectionPoint = ginput(1);
        
        %Sets limit for image subsetx`
        xvalue = selectionPoint(1);
        yvalue = selectionPoint(2);
   
        xmin = xvalue - pixelRangeX
        xmax = xvalue + pixelRangeX
        
        ymin = yvalue - pixelRangeX
        ymax = yvalue + pixelRangeX
        
        zmin = sliderPositon
        zmax = sliderPositon + pixexlRangeZ
        
        %Seperates out subset of image set
        reducedMatrix = matrix(xmin:xmax,ymin:ymax,zmin:zmax);
        modelView(reducedMatrix)
        
    end

%%% callback for testing the threshholding funtion 
    function threshholdAnalysisCallback(hObject,event)
        standardThreshHoldInit();
        
    end


%% Calculation and Calibration Functions
%% Calibrate using Water / Air Standards. 
    function waterAirCalibration()
             %%%%%%%%%%%%%%%%%%%%%%%%%%Values of EXPECTED standard values %%%%%%%%%%%%%%%%%%%%%%%%%%
            HU1 = -1000;
            HU2 = 0;
            HU3 = NaN;
            HU4 = NaN;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Number of pixels to exclude
            pixel_reduc = 1;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %ensures mark1 is less than mark2
            choice = questdlg('Verify you have selected first and last slice.',' ', 'OK','Cancel');
            switch choice     
            case 'OK'
                
            case 'Cancel'
                return   
            end
            
            %Verifies correct order for first and second marks
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            %Number 1/2 width of box that will be shown when zooming in for
            %standard calibration
            viewLength = 20;
            
            %Switches between first and last slice, allowing using to
            %select center of stanadard ROI. Prompts user for center of ROI
            %after slice has been displayed.
            viewMark1();
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
            CenterM1 = ginput(1);
            
            %Pixel correction for X Y location selection 
            CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
            CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
            
            %Switches between first and last slice, allowing using to
            %select center of stanadard ROI. Prompts user for center of ROI
            %after slice has been displayed.
            viewMark2()
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
            CenterM2 = ginput(1);
            
            %Pixel correction for X Y location selection 
            CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
            CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;
            
            %Prompts user to enter radius to be used for RoI
            radius = input('Please specify what radius you would like to use\n');
            
            %Calculates center of RoI for each slice between first and last
            %slice based on simple y = mx+b formula.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            %Iterates through each of the four standards, allowing the user
            %to select which standard they are calibrating.
            numCalib = 2;
            for calib = [1:numCalib]
                if calib > 1
                    
                    %Switches between first and last slice, allowing using to
                    %select center of stanadard ROI. Prompts user for center of ROI
                    %after slice has been displayed.
                    msgbox(sprintf('Please indicate Mark1, Mark2 and center of standard #%d, then press the Enter key in the command window',calib))
                    pause
                    viewMark1()
                    CenterZoom = ginput(1);
                    displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
                    CenterM1 = ginput(1);
                    CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
                    CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
                    viewMark2()
                    CenterZoom = ginput(1);
                    displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
                    CenterM2 = ginput(1);
                    CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
                    CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;         
                    
                    %Calculates center of RoI for each slice between first and last
                    %slice based on simple y = mx+b formula.
                    deltay = double(CenterM2(2))-double(CenterM1(2))
                    deltaz = mark2 - mark1
                    my = double(deltay)/double(deltaz)
                    by = double(CenterM1(2)) -double(my)*double(mark1)
                    deltax = double(CenterM2(1))-double(CenterM1(1))
                    mx = double(deltax)/double(deltaz)
                    bx = double(CenterM1(1))- double(mx)*double(mark1)
                end
                

                cd(firstDir)
                %Defines the number of slices to be averaged
                count = int16(mark2-mark1);
                %Defines size of data to be collected
                struct1 = size(matrix);
                
                %Creates appropriately sized array depending on the view of
                %user selected view.
                if viewType == 1
                    struct = zeros(count, struct1(1), struct1(2));
                elseif viewType == 2 
                    struct = zeros(count, struct1(1), struct1(3));   
                elseif viewType == 3
                    struct = zeros(count, struct1(2), struct1(3));
                end
                
                %Stores EVERY value calculated from standard.
                avgStruct = [];
                
                %Iterates through each and calcuates the average GS values
                %over area of interest
                for slicenumber = mark1:mark2
                    
                    locationX = (double(slicenumber)*double(mx))+bx;
                    locationY = (double(slicenumber)*double(my))+by;
                    Center = [double(locationX), double(locationY)];
                  
                    %Chooses appropriate slice depending on user view. 
                    if viewType == 1
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1),pixel_reduc);
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;

                    elseif viewType == 2
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1),pixel_reduc);
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;


                    elseif viewType == 3
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1),pixel_reduc);
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;

                    end
                    
                    %Stores avg value calucalted from slice
                    struct(slicenumber - mark1 + 1,:,:) = tempStruct;
                    
                    
                end
                
                totalValue = avgStruct;
                totalAverage = mean2(struct);
                STD = std(double(struct));
              
                %Generates statistics for each standard.
                if calib == 1;
                    TV1 = totalValue;
                    PV1 = totalAverage;
                    PV1std = STD(1);
                elseif calib == 2;
                    TV2 = totalValue;
                    PV2 = totalAverage;
                    PV2std = STD(1);
                end
            end
            HounsfieldUnitmat = [HU1;HU2;];
            Dmat = [PV1; PV2;];
            plotfig = figure(3);
            
            %Here we are solving for the rescale coeff. using the average
            %PV. Below we will then use average PV values for each slice to
            %solve for the rescale coeff for each slice. 
            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            f1 = fit(Dmat, HounsfieldUnitmat, 'exp1');
            RS_lin = rescale(1);
            RI_lin = rescale(2);
            fixHU_lin = (Dmat*RS_lin) +RI_lin;

            figure(plotfig)
            subplot(3,1,1)
            plot(Dmat, fixHU_lin, 'r--')
            hold on
            plot(Dmat, HounsfieldUnitmat, 'k+', 'MarkerSize', 15)
            hold off
            
            %Histogram Visualization for each standard
            subplot(3,1,2)
            s1Hist = histogram(TV1)
            s1Hist.BinEdges = [0:5500];
            
            title('Air Histogram')
            size(TV1)
            S1Data = [[PV1,PV1std],TV1];
            S1Data = S1Data.';
            
            subplot(3,1,3)
            s2Hist = histogram(TV2)
            s2Hist.BinEdges = [0:5500];
            title('Water Histogram')
            S2Data = [[PV2,PV2std],TV2];
            S2Data = S2Data.';
            
            
            % Displays the mean and standard deviation of the GSV data

            display = msgbox({['Mean 1 = ' num2str(mean2(TV1))]; ['Std 1 = ' num2str(std(double(TV1)))]; ['Mean 2 = ' num2str(mean2(TV2))]; ['Std 2 = ' num2str(std(double(TV2)))];});
            choice = questdlg('Use the linear or exponential fit for calibration?',' ', 'Linear','Cancel','Cancel');
            
            switch choice     
            case 'Linear'
                
                %vol = DICOM2VolumeCBCT(dirname);
                cd(firstDir)
                %calibratedDir = GenerateCalibratedDicoms(dirname,vol,"standard",RS_lin,RI_lin)
                saveas(gcf,'CalibrationData.png')
                
                
                %Remove data that is greater than 2-3 STD from the mean
                threshVal = 1.5;
                mean = mean2(S1Data);
                stddev = std(S1Data);
                rmArray = [];
                
                for i = 1:length(S1Data)
                    
                    if S1Data(i) < mean - (threshVal * stddev)
                        rmArray=[rmArray,i];

                    elseif S1Data(i) > mean + (threshVal * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S1Data(rmVal) = [];
                end
                
                %Remove data that is greater than 2-3 STD from the mean
                mean = mean2(S2Data);
                stddev = std(S2Data);
                rmArray = [];
                for i = 1:length(S2Data)
                    
                    if S2Data(i) < mean - (threshVal * stddev)
                        rmArray=[rmArray,i];
                    elseif S2Data(i) > mean + (threshVal * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S2Data(rmVal) = [];
                end
                
                %Ensures that each array has the same number of elements,
                %length is choosen as smallest length of th setl
                if length(S1Data) < length(S2Data)
                    
                    
                    dataCatIndex = length(S1Data);
                else
                    dataCatIndex = length(S2Data);
                end
                
            
                %Array containing values for each standard in a different
                %column. 
                SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex)];
                
                cd(dirname)
                %Writes raw standard data as .csv file
                dlmwrite('RawDataStandard.csv',SData,'roffset',1,'coffset',0,'-append')
                cd(firstDir)
                %Generates distribution of RS and RI values based on raw
                %standard data. 
                GenerateRescaleDist(SData,HU1,HU2,HU3,HU4,dirname)   
              
            %Does nothing if calibration data is not sufficient.     
            case 'Cancel'
                
            end
            updateImage()
           
    end
   
    %% Calibration using HA-HDPE Samples. 
    %Allows the user to create a set of rescale intercept and rescale slope
    %pairs for later use. The user will enter the EXPECTED Hounsfield units
    %of each of the standards, manually locate each standard and create a
    %set of calibration curves using a guassian distribution. 
    function standardCalibration()
             
            %%%%%%%%%%%%%%%%%%%%%%%%%%Values of EXPECTED standard values %%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%% If standard four is set to NAN, calibration will only
            %%%%% occur three standards.
            %Lowest Standard is 27%
            HU1 = 2112; %For 18kEv
            HU1 = 923; %Fir 40kEv
            %Middle Standard is 45%
            HU2 = 4301.6; %For 18kEv
            HU2 = 1824; %For 40kEv
            %most dense standard is 61%cler
            HU3 = 6628.6; %For 18kEv
            HU3 = 2953; %For 40kEv
            
            HU4 = 12012;
            HU4 = nan;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Number of pixels to exclude
            pixel_reduc = 0;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %ensures mark1 is less than mark2
            choice = questdlg('Verify you have selected first and last slice.',' ', 'OK','Cancel');
            switch choice     
            case 'OK'
                
            case 'Cancel'
                return   
            end
            
            %Verifies correct order for first and second marks
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            %Number 1/2 width of box that will be shown when zooming in for
            %standard calibration
            viewLength = 20;
            
            %Switches between first and last slice, allowing using to
            %select center of stanadard ROI. Prompts user for center of ROI
            %after slice has been displayed.
            viewMark1();
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
            CenterM1 = ginput(1);
            
            %Pixel correction for X Y location selection 
            CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
            CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
            
            %Switches between first and last slice, allowing using to
            %select center of stanadard ROI. Prompts user for center of ROI
            %after slice has been displayed.
            viewMark2()
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
            CenterM2 = ginput(1);
            
            %Pixel correction for X Y location selection 
            CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
            CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;
            
            %Prompts user to enter radius to be used for RoI
            radius = input('Please specify what radius you would like to use\n');
            
            %Calculates center of RoI for each slice between first and last
            %slice based on simple y = mx+b formula.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            %Iterates through each of the four standards, allowing the user
            %to select which standard they are calibrating.
            if ~isnan(HU4)
                numCalib = 4;
            else 
                numCalib = 3;
            end
            
            for calib = [1:numCalib]
                if calib > 1
                    
                    %Switches between first and last slice, allowing using to
                    %select center of stanadard ROI. Prompts user for center of ROI
                    %after slice has been displayed.
                    msgbox(sprintf('Please indicate Mark1, Mark2 and center of standard #%d, then press the Enter key in the command window',calib))
                    pause
                    viewMark1()
                    CenterZoom = ginput(1);
                    displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
                    CenterM1 = ginput(1);
                    CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
                    CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
                    viewMark2()
                    CenterZoom = ginput(1);
                    displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
                    CenterM2 = ginput(1);
                    CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
                    CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;         
                    
                    %Calculates center of RoI for each slice between first and last
                    %slice based on simple y = mx+b formula.
                    deltay = double(CenterM2(2))-double(CenterM1(2))
                    deltaz = mark2 - mark1
                    my = double(deltay)/double(deltaz)
                    by = double(CenterM1(2)) -double(my)*double(mark1)
                    deltax = double(CenterM2(1))-double(CenterM1(1))
                    mx = double(deltax)/double(deltaz)
                    bx = double(CenterM1(1))- double(mx)*double(mark1)
                end
                

                cd(firstDir)
                %Defines the number of slices to be averaged
                count = int16(mark2-mark1);
                %Defines size of data to be collected
                struct1 = size(matrix);
                
                %Creates appropriately sized array depending on the view of
                %user selected view.
                if viewType == 1
                    struct = zeros(count, struct1(1), struct1(2));
                elseif viewType == 2 
                    struct = zeros(count, struct1(1), struct1(3));   
                elseif viewType == 3
                    struct = zeros(count, struct1(2), struct1(3));
                end
                
                %Stores EVERY value calculated from standard.
                avgStruct = [];
                
                %Iterates through each and calcuates the average GS values
                %over area of interest
                for slicenumber = mark1:mark2
                    
                    locationX = (double(slicenumber)*double(mx))+bx;
                    locationY = (double(slicenumber)*double(my))+by;
                    Center = [double(locationX), double(locationY)];
                  
                    %Chooses appropriate slice depending on user view. 
                    if viewType == 1
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1),pixel_reduc);
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;

                    elseif viewType == 2
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1),pixel_reduc);
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;


                    elseif viewType == 3
                        [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1),pixel_reduc);
                        avgStruct = [avgStruct, gsValues];
                        tempStruct = avgValue;

                    end
                    
                    %Stores avg value calucalted from slice
                    struct(slicenumber - mark1 + 1,:,:) = tempStruct;
                    
                    
                end
                
                totalValue = avgStruct;
                totalAverage = mean2(struct);
                STD = std(double(struct));
              
                %Generates statistics for each standard.
                if calib == 1;
                    TV1 = totalValue;
                    PV1 = totalAverage;
                    PV1std = STD(1);
                elseif calib == 2;
                    TV2 = totalValue;
                    PV2 = totalAverage;
                    PV2std = STD(1);
                elseif calib == 3
                    TV3 = totalValue;
                    PV3 = totalAverage;
                    PV3std = STD(1);
                elseif calib == 4
                    TV4 = totalValue;
                    PV4= totalAverage;
                    PV4std = STD(1);
                end
            end
            if ~isnan(HU4)
                            
                HounsfieldUnitmat = [HU1;HU2;HU3;HU4;];
                Dmat = [PV1; PV2; PV3; PV4;];
            else
                HounsfieldUnitmat = [HU1;HU2;HU3;];
                Dmat = [PV1; PV2; PV3;];

            end

            
            plotfig = figure(3);
            
            %Here we are solving for the rescale coeff. using the average
            %PV. Below we will then use average PV values for each slice to
            %solve for the rescale coeff for each slice. 
            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            f1 = fit(Dmat, HounsfieldUnitmat, 'exp1');
            RS_lin = rescale(1);
            RI_lin = rescale(2);
            fixHU_lin = (Dmat*RS_lin) +RI_lin;

            figure(plotfig)
            subplot(5,1,1)
            plot(Dmat, fixHU_lin, 'r--')
            hold on
            plot(Dmat, HounsfieldUnitmat, 'k+', 'MarkerSize', 15)
            hold off
            
            %Histogram Visualization for each standard
            subplot(5,1,2)
            s1Hist = histogram(TV1)
            s1Hist.BinEdges = [0:5500];
            
            title('Standard 1 Histogram')
            size(TV1)
            S1Data = [[PV1,PV1std],TV1];
            S1Data = S1Data.';
            
            subplot(5,1,3)
            s2Hist = histogram(TV2)
            s2Hist.BinEdges = [0:5500];
            title('Standard 2 Histogram')
            S2Data = [[PV2,PV2std],TV2];
            S2Data = S2Data.';
            
            subplot(5,1,4)
            s3Hist = histogram(TV3)
            s3Hist.BinEdges = [0:5500];
            title('Standard 3 Histogram')
            S3Data = [[PV3,PV3std],TV3];
            S3Data = S3Data.';
            
            if ~isnan(HU4)
                subplot(5,1,5)
                s3Hist = histogram(TV4)
                s3Hist.BinEdges = [0:5500];
                title('Standard 4 Histogram')
                S4Data = [[PV4,PV4std],TV4];
                S4Data = S4Data.';
            end
            
            % Displays the mean and standard deviation of the GSV data
            if ~isnan(HU4)
                display = msgbox({['Mean 1 = ' num2str(mean2(TV1))]; ['Std 1 = ' num2str(std(double(TV1)))]; ['Mean 2 = ' num2str(mean2(TV2))]; ['Std 2 = ' num2str(std(double(TV2)))]; ['Mean 3 = ' num2str(mean2(TV3))]; ['Std 3 = ' num2str(std(double(TV3)))]; ['Mean 4 = ' num2str(mean2(TV4))]; ['Std 4 = ' num2str(std(double(TV4)))]});
            else
                display = msgbox({['Mean 1 = ' num2str(mean2(TV1))]; ['Std 1 = ' num2str(std(double(TV1)))]; ['Mean 2 = ' num2str(mean2(TV2))]; ['Std 2 = ' num2str(std(double(TV2)))]; ['Mean 3 = ' num2str(mean2(TV3))]; ['Std 3 = ' num2str(std(double(TV3)))]});
            end
            
            choice = questdlg('Use the linear or exponential fit for calibration?',' ', 'Linear','Cancel','Cancel');
            
            switch choice     
            case 'Linear'
                
                %vol = DICOM2VolumeCBCT(dirname);
                cd(firstDir)
                %calibratedDir = GenerateCalibratedDicoms(dirname,vol,"standard",RS_lin,RI_lin)
                saveas(gcf,'CalibrationData.png')
                
                
                %Remove data that is greater than 2-3 STD from the mean
                threshVal = 1.5;
                mean = mean2(S1Data);
                stddev = std(S1Data);
                rmArray = [];
                
                for i = 1:length(S1Data)
                    
                    if S1Data(i) < mean - (threshVal * stddev)
                        rmArray=[rmArray,i];

                    elseif S1Data(i) > mean + (threshVal * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S1Data(rmVal) = [];
                end
                
                %Remove data that is greater than 2-3 STD from the mean
                mean = mean2(S2Data);
                stddev = std(S2Data);
                rmArray = [];
                for i = 1:length(S2Data)
                    
                    if S2Data(i) < mean - (threshVal * stddev)
                        rmArray=[rmArray,i];
                    elseif S2Data(i) > mean + (threshVal * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S2Data(rmVal) = [];
                end
                %Remove data that is greater than 2-3 STD from the mean
                mean = mean2(S3Data);
                stddev = std(S3Data);
                rmArray = [];
                for i = 1:length(S3Data)
                    
                    if S3Data(i) < mean - (threshVal * stddev)
                        rmArray=[rmArray,i];
                    elseif S3Data(i) > mean + (threshVal * stddev)
                        rmArray=[rmArray,i];
                    else
                        
                    end
                end
                for i = 1:length(rmArray)
                    rmVal = rmArray(i);
                    rmVal = rmVal - i + 1;
                    S3Data(rmVal) = [];
                end
                
                if ~isnan(HU4)
                    %Remove data that is greater than 2-3 STD from the mean
                    mean = mean2(S4Data);
                    stddev = std(S4Data);
                    rmArray = [];
                    for i = 1:length(S4Data)

                        if S4Data(i) < mean - (threshVal * stddev)
                            rmArray=[rmArray,i];
                        elseif S4Data(i) > mean + (threshVal * stddev)
                            rmArray=[rmArray,i];
                        else

                        end
                    end
                    for i = 1:length(rmArray)
                        rmVal = rmArray(i);
                        rmVal = rmVal - i + 1;
                        S4Data(rmVal) = [];
                    end 
                end
                %Ensures that each array has the same number of elements,
                %length is choosen as smallest length of th setl
                if length(S1Data) < length(S2Data)
                    dataCatIndex = length(S1Data);
                else
                    dataCatIndex = length(S2Data);
                end
                
                if length(S3Data) < dataCatIndex
                    dataCatIndex = length(S3Data);
                end
                if ~isnan(HU4)
                    if length(S4Data) < dataCatIndex
                        dataCatIndex = length(S4Data);
                    end
                end
                %Array containing values for each standard in a different
                %column. 
                if ~isnan(HU4)
                    SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex), S3Data(1:dataCatIndex), S4Data(1:dataCatIndex)];
                else
                    SData = [S1Data(1:dataCatIndex), S2Data(1:dataCatIndex), S3Data(1:dataCatIndex)];
                end
                
                cd(dirname)
                %Writes raw standard data as .csv file
                dlmwrite('RawDataStandard.csv',SData,'roffset',1,'coffset',0,'-append')
                cd(firstDir)
                %Generates distribution of RS and RI values based on raw
                %standard data. 
                GenerateRescaleDist(SData,HU1,HU2,HU3,HU4,dirname)
                
                
              
            %Does nothing if calibration data is not sufficient.     
            case 'Cancel'
                
            end
            updateImage()
    end


%% Takes measurement based on current dataset. Uses the rescale slope and
%rescale intercept written into the dicom file. 
    function takeMeasurement(hObject, event)
            clear avgStruct
            cd(firstDir)
            
            pixel_reduc = 0;
            %ensures mark1 is before mark2
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            count = int16(mark2-mark1);
            struct=[count];
            struct1=size(matrix);
            struct2 = [struct1(1), struct1(2)];
            m = 0;
            
            %Defines the number of pixels that will be displayed after
            %center of ROI is specified,
            viewLength=20;
            
            %Displays first mark defined by user.
            viewMark1()
            
            %Askes user to specify center of ROI. First click will provide
            %a zoomed area of the region, second click will allow the user
            %to find the center of the image. Does the proper transforms
            %for the image to convert from zoomed area to full area.
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
            CenterM1 = ginput(1);
            CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
            CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
            
            %Displays second mark defined by user.
            viewMark2()
            %Askes user to specify center of ROI. First click will provide
            %a zoomed area of the region, second click will allow the user
            %to find the center of the image. Does the proper transforms
            %for the image to convert from zoomed area to full area.
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
            CenterM2 = ginput(1);
            CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
            CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;
            
            %Alows users to specify the radius of the area of interest for
            %averaging.
            prompt = {'Number of radii to evaluate:','Starting radius:','Ending Radius:'};
                windowtitle = 'Evaluation parameters';
                dims = [1 50];
                definput = {'1','5','N/A'};
                answer = inputdlg(prompt,windowtitle,dims,definput);
            numbofradi = str2num(answer{1});
            firstradius = str2num(answer{2});
            lastradius = str2num(answer{3});
            if ~isempty(lastradius)
                delta = (lastradius - firstradius)/numbofradi;
                radius = zeros(((lastradius-firstradius)/delta)+1,1);
                tempradius = firstradius;
                for i = 1:length(radius)
                    radius(i) = tempradius; 
                    tempradius = tempradius + delta;
                end
            else
                radius = firstradius;
            end            
            %Computes proper transforms for each slice. Simply y = mx+b
            %from center of mark 1 to center of mark 2.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            avgStruct = [];   
            
            %Iterates over each slice finding the average value of
            %grayscale value value depending on user specificied view.
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];

                %Uses difference slice depending on user selected view.
                %Takes a slice from the "matrix", provides x,y and R and
                %calculates the average of the area.   
                if viewType == 1
                    
                    filterraw = squeeze(matrix(:,:,slicenumber));
                    %filterimg = wiener2(filterraw);
                    %filterimg = medfilt2(filterraw);
                    
                    [avgValue,gsValues] = CircularAVG(filterraw, radius, Center(2), Center(1),pixel_reduc);
                    
                    %figure(10);
                    %imshowpair(filterraw,filterimg,'montage')
                    
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                    
                elseif viewType == 2
                    
                    filterraw = squeeze(matrix(:,slicenumber,:));
                    %filterimg = wiener2(squeeze(matrix(:,slicenumber,:)));
                    %filterimg = medfilter2(filterraw);
                    %figure(10);
                    %imshowpair(filterraw,filterimg,'montage')
                    
                    
                    [avgValue,gsValues] = CircularAVG(filterraw, radius, Center(2), Center(1),pixel_reduc);
                    
                   
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                    
                elseif viewType == 3
                    filterraw = squeeze(matrix(slicenumber,:,:));
                    %filterimg = wiener2(squeeze(matrix(slicenumber,:,:)));
                    %filterimg = medfilter2(filterraw);
                    [avgValue,gsValues] = CircularAVG(filterraw, radius, Center(2), Center(1),pixel_reduc);
                    
                    %figure(10);
                    %imshowpair(filterraw,filterimg,'montage')
                    
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                end
                
                struct(slicenumber - mark1 + 1) = tempStruct;
                
            end
          
            
            
           
            %Remove data that is greater than 2-3 STD from the mean
            threshVal = 1.5;
            mean = mean2(avgStruct);
            stddev = std(avgStruct);
            rmArray = [];

            for i = 1:length(avgStruct)

                if avgStruct(i) < mean - (threshVal * stddev)
                    rmArray=[rmArray,i];

                elseif avgStruct(i) > mean + (threshVal * stddev)
                    rmArray=[rmArray,i];
                else

                end
            end

            for i = 1:length(rmArray)
                rmVal = rmArray(i);
                rmVal = rmVal - i + 1;
                avgStruct(rmVal) = [];
            end
      
            
            HUs = [];
            for structnumber = 1:length(struct)
                rescaleint(structnumber)= ginfo1{structnumber-1+mark1}.RescaleIntercept;
                rescaleint(structnumber) = -9736.532484
                rescaleslope(structnumber)= ginfo1{structnumber-1+mark1}.RescaleSlope;
                rescaleslope(structnumber) = 9.364985706;
                struct = double(struct);
                HUstruct(structnumber) = (rescaleslope(structnumber)*struct(structnumber))+rescaleint(structnumber);
            end
           
            
            
            for i = 1:length(avgStruct)
                tempHUs(i) = (rescaleslope(structnumber)*avgStruct(i))+rescaleint(structnumber);
            end
            HUs = [HUs tempHUs];
        
            %Plots data showing dist. of grayscale values. 
            plotfig = figure(3);
            figure(plotfig)
            subplot(2,1,1)
            h = histogram(avgStruct)
            h.BinEdges = [0:min(avgStruct)+range(avgStruct)+1000];
            h.NumBins = 100;
            axis tight
            title('Dist. of Grayscale over Volume of Interest')
            avgStr = (strcat('Avg. GSV: ', num2str(mean2(avgStruct))));
            stdStr = (strcat('Std. GSV: ', num2str(std(double(avgStruct)))));
            h = annotation('textbox',[0.58 0.75 0.1 0.1]);          
            set(h,'String',{avgStr,stdStr});
            subplot(2,1,2)
            % Plots data showing distribution of HU values.
            HUs = HUs';
            h1 = histogram(HUs)
            h1.BinEdges = [0:min(HUs)+range(HUs)+1000];
            h1.NumBins = 100;
            axis tight
            title('Dist. of HU over Volume of Interest')
            
            
            %Transforms each grayscale value based on rescale slope and
            %rescale intercept of written into the dicom file.
      
            
           rangeofGSV = range(struct);
           rangeofHU = range(HUstruct);
           xaxis = mark2-mark1+2;

           %Flips axis based on ranges of HU and GS values. 
           if rangeofGSV>rangeofHU
               yaxismax = round(min(struct)+(rangeofGSV+(.5*rangeofGSV)));
               yaxismin = round(min(struct)-(.5*rangeofGSV));
               plotaxis = 1;
               axis([-1 150 yaxismin yaxismax])
           elseif rangeofGSV<rangeofHU
               plotaxis = 0;
               yaxismax = round(min(struct)+(rangeofHU+(.5*rangeofHU)));
               yaxismin = round(min(struct)-(.5*rangeofHU));
               axis([-1 150 yaxismin yaxismax])
           end 
           
           % For analyzing HU as a function of slice number:
%            plot(HUstruct);
%            title('Avg HU Units versus Slice Number')
%            xlabel('Number of Slices')
%            ylabel('PV in HU')

           sixstruct = int16(struct);
           sixstruct = sixstruct +32767;
           total(m) = mean2(sixstruct)
           totalAverage(m) = mean2(struct)
           STD(m) = std(HUstruct)
           HU(m) = mean2(HUstruct)
           
           
           avgStr = (strcat('Avg. HU: ', string(mean2(HUs))))
           stdStr = (strcat('Std. HU: ',string(std(double(avgStruct)))))
           
%            label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 100 100 32]);
%            label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 50 100 32]);
%           
    end


%% Takes measurement based on current dataset. Uses the rescale slope and
%rescale intercept written into the dicom file. 
    function takeLineMeasurement(hObject, event)
            clear avgStruct
            cd(firstDir)
            %ensures mark1 is before mark2
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            count = int16(mark2-mark1);
            struct=[count];
            struct1=size(matrix);
            struct2 = [struct1(1), struct1(2)];
            m = 0;
            
            pixel_reduc = 0;
            
            %Defines the number of pixels that will be displayed after
            %center of ROI is specified,
            viewLength=20;
            
            %Displays first mark defined by user.
            viewMark1()
            
            %Askes user to specify center of ROI. First click will provide
            %a zoomed area of the region, second click will allow the user
            %to find the center of the image. Does the proper transforms
            %for the image to convert from zoomed area to full area.
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
            CenterM1 = ginput(1);
            CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
            CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
            
            %Displays second mark defined by user.
            viewMark2()
            %Askes user to specify center of ROI. First click will provide
            %a zoomed area of the region, second click will allow the user
            %to find the center of the image. Does the proper transforms
            %for the image to convert from zoomed area to full area.
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
            CenterM2 = ginput(1);
            CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
            CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;
            
            %Alows users to specify the radius of the area of interest for
            %averaging.
            prompt = {'Number of radii to evaluate:','Starting radius:','Ending Radius:'};
                windowtitle = 'Evaluation parameters';
                dims = [1 50];
                definput = {'1','5','N/A'};
                answer = inputdlg(prompt,windowtitle,dims,definput);
            numbofradi = str2num(answer{1});
            firstradius = str2num(answer{2});
            lastradius = str2num(answer{3});
            if ~isempty(lastradius)
                delta = (lastradius - firstradius)/numbofradi;
                radius = zeros(((lastradius-firstradius)/delta)+1,1);
                tempradius = firstradius;
                for i = 1:length(radius)
                    radius(i) = tempradius; 
                    tempradius = tempradius + delta;
                end
            else
                radius = firstradius;
            end            
            %Computes proper transforms for each slice. Simply y = mx+b
            %from center of mark 1 to center of mark 2.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            avgStruct = [];   
            
            %Iterates over each slice finding the average value of
            %grayscale value value depending on user specificied view.
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];

                %Uses difference slice depending on user selected view.
                %Takes a slice from the "matrix", provides x,y and R and
                %calculates the average of the area.   
                if viewType == 1
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1),pixel_reduc);
                    
                   
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                    
                elseif viewType == 2
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1),pixel_reduc);
                    
                   
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                    
                elseif viewType == 3
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1),pixel_reduc);
                    
                   
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                end
                
                struct(slicenumber - mark1 + 1) = tempStruct;
                
            end
            
            HUs = [];
            for structnumber = 1:length(struct)
                rescaleint(structnumber)= ginfo1{structnumber-1+mark1}.RescaleIntercept;
                rescaleslope(structnumber)= ginfo1{structnumber-1+mark1}.RescaleSlope;
                struct = double(struct);
                HUstruct(structnumber) = (rescaleslope(structnumber)*struct(structnumber))+rescaleint(structnumber);
            end
            for i = 1:length(avgStruct)
                tempHUs(i) = (rescaleslope(structnumber)*avgStruct(i))+rescaleint(structnumber);
            end
            HUs = [HUs tempHUs];
        
            %Plots data showing dist. of grayscale values. 
            plotfig = figure(3);
            figure(plotfig)
            p = polyfit([1:1:length(struct)],struct,2)
            poly = polyval(p,[1:1:length(struct)]); 
            plot([1:1:length(struct)],struct);
            hold on;
            plot([1:1:length(struct)],poly)
            ylim([-500 1500])
            title('Slice # Vs Grayscale Value')
            xlabel('Slice #')
            
            
            
           
%           
    end


%% Takes measurement based on current dataset, this function asks the user 
%to specify a csv file with sets of rescale intercept and rescale slope values. 
%This list can either be generated through the calibration function or can 
%be specificed by the user. This will end by generating a csv file with
%every calculated housnfeild unit from the average grayscale value based on
%supplied rs and ri values.
    function takeMeasurementWithDist()
            
            clear avgStruct
            pixel_reduc = 1;
            
            %Askes the user to specifc the location of the CSV file
            %containing the rescale slope and rescale intercept values.
            [dirname] = uigetdir('*.csv','Please choose CSV directory');
            cd(dirname)
            [filename] = uigetfile('*.csv','Please choose CSV directory');
            rs_ri_Vals = csvread(filename);
            
            %Structs containing information regarding all of the rescale
            %intercept and rescale values. 
            RS_Vals = rs_ri_Vals(1:end,1);
            RI_Vals = rs_ri_Vals(1:end,2);
            
            cd(firstDir)
            %ensures mark1 is before mark2
            if(mark1>mark2)
                tempVar = mark1;
                mark1=mark2;
                mark2 = tempVar;
            end
            
            count = int16(mark2-mark1);
            struct=[count];
            struct1=size(matrix);
            struct2 = [struct1(1), struct1(2)];
            m = 0;
            
            
            %Defines the number of pixels that will be displayed after
            %center of ROI is specified,
            viewLength=20;
            
            %Switches to first marked location.
            viewMark1()
            %Transformation for zoom
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,1);
            CenterM1 = ginput(1);
            CenterM1(1) = CenterM1(1) + CenterZoom(1)-viewLength;
            CenterM1(2) = CenterM1(2) + CenterZoom(2)-viewLength;
            
            %Switches to second marked location.
            viewMark2()
            %Transformation for zoom
            CenterZoom = ginput(1);
            displayImageSubset(CenterZoom(1), CenterZoom(2),viewLength,2);
            CenterM2 = ginput(1);
            CenterM2(1) = CenterM2(1) + CenterZoom(1)-viewLength;
            CenterM2(2) = CenterM2(2) + CenterZoom(2)-viewLength;

            %Prompts the user for a radius for area of interest.
            radius = input('Please specify what radius you want to start with\n');
            
            %Calculates parameters for finding roi over each slice.
            deltay = double(CenterM2(2))-double(CenterM1(2))
            deltax = double(CenterM2(1))-double(CenterM1(1))
            deltaz = mark2 - mark1
            
            my = double(deltay)/double(deltaz)
            by = double(CenterM1(2)) -double(my)*double(mark1)
            
            mx = double(deltax)/double(deltaz)
            bx = double(CenterM1(1))- double(mx)*double(mark1)
            
            m = m+1;
            matrixSize = size(matrix);
            
            avgStruct = []  
    
            %This loop iterates over each speccified slice (between Mark 1
            %and Mark 2 inclusive) and calcuates the averageg grayscale
            %value of the area. 
            for slicenumber = mark1:mark2

                locationX = (double(slicenumber)*double(mx))+bx;
                locationY = (double(slicenumber)*double(my))+by;
                Center = [double(locationX), double(locationY)];
            
                %Uses difference slice depending on user selected view.
                %Takes a slice from the "matrix", provides x,y and R and
                %calculates the average of the area. 
                if viewType == 1                    
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,:,slicenumber)), radius, Center(2), Center(1),pixel_reduc);
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;

                elseif viewType == 2
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(:,slicenumber,:)), radius, Center(2), Center(1),pixel_reduc);
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;


                elseif viewType == 3
                    [avgValue,gsValues] = CircularAVG(squeeze(matrix(slicenumber,:,:)), radius, Center(2), Center(1),pixel_reduc);
                    avgStruct = [avgStruct, gsValues];
                    tempStruct = avgValue;
                end

                struct(slicenumber - mark1 + 1) = tempStruct;

            end

            %This struct contains the total number of average slice values.
            %
            totalAvgValues = [length(RS_Vals)];
            
            %This loop computes an equivelant hounsfeild unit for every
            %rescale intercept and rescale slope supplied. This loop uses
            %the parallel computing toolbox. The more cores your computer
            %has the faster it goes.
            avgGS = mean2(struct);

            %{
            parfor rs_value_index = 1:length(totalAvgValues)
            
               HUstruct = [];
               
               for structnumber = 1:length(struct)
                   
                   HUstruct(structnumber) = (RS_Vals(rs_value_index)*struct(structnumber))+RI_Vals(rs_value_index);
                    
               end

               totalAvgValues(rs_value_index) = mean2(HUstruct);

            end
            %}
            
            HUstruct = zeros(length(RS_Vals),length(gsValues));
            HUstruct = [];
            
            parfor rs_value_index = 1:length(RS_Vals)
           
               HUSubStruct = [length(gsValues)];
               for gsValue = 1:length(gsValues)
                   
                   HUSubStruct(gsValue) = (RS_Vals(rs_value_index)*gsValues(gsValue))+RI_Vals(rs_value_index);
                    
               end
               
               HUstruct  = [HUstruct,HUSubStruct];
            end
            
            totalAvgValues = HUstruct(:)
            plotfig = figure(5);
            figure(plotfig)

            totalAvgValues = totalAvgValues.';
            %{
            for k=length(totalAvgValues):-1:1
                if(totalAvgValues(k) < 0)
                    totalAvgValues(k) = [];
                end
            end
            meanStd = (mean2(totalAvgValues)+std(totalAvgValues));
            for k=length(totalAvgValues):-1:1
                if(totalAvgValues(k) > meanStd)
                    totalAvgValues(k) = [];
                end
            end
            %}
            cd(dirname)
            
            %Wites a csv file with all calcuated hounsfeild units. 
            dlmwrite('totalAvgValuestest.csv',totalAvgValues,'roffset',1,'coffset',0,'-append')

            x = 0:100:10000;
            hold on;
            h1 = histogram(totalAvgValues,x)
            xlabel('HU');
            ylabel('Count');
            title('Dist. of HU over Volume of Interest')
            avgStr = (strcat('Avg. HU: ', num2str(mean2(totalAvgValues))));
            stdStr = (strcat('Std. HU: ', num2str(std(double(totalAvgValues)))));
            if measurementCount == 1
                h = annotation('textbox',[0.58 0.65 0.1 0.1]);          
                set(h,'String',{avgStr,stdStr})
            elseif measurementCount ==2
                h = annotation('textbox',[0.68 0.75 0.1 0.1]);          
                set(h,'String',{avgStr,stdStr})
            else
                h = annotation('textbox',[0.78 0.85 0.1 0.1]);          
                set(h,'String',{avgStr,stdStr})
            end
            measurementCount = measurementCount + 1;
           
           %label2 = uicontrol('Style', 'text','Parent', plotfig, 'String', avgStr,'Position',[100 measurementCount*100 100 32]);
           %label1 = uicontrol('Style', 'text','Parent', plotfig, 'String', stdStr,'Position',[100 (measurementCount-1)*50+50 100 32]);
          
    end
%% This function updates slice based on slider value
    function updateImage()
        
        figure(f)
        if viewType == 1
            imshow(squeeze(matrix(:,:,sliderPositon)),[0 6000]);
            title(['Slice Number ' num2str(sliderPositon)])
            drawnow;   
        elseif viewType == 2
            imshow(squeeze(matrix(:,sliderPositon,:)),[0 6000]);
            title(['Slice Number ' num2str(sliderPositon)])
            drawnow;
        elseif viewType == 3
            imshow(squeeze(matrix(sliderPositon,:,:)),[0 6000]);
            title(['Slice Number ' num2str(sliderPositon)])
            drawnow;
        else
        end
        
    end

%% This function updates based on giving volume
    function displayImageSubset(x,y,viewLength,mark)
        if mark == 1
            n = mark1;
        else
            n = mark2;
        end
        
        figure(f)
        if viewType == 1
            vol = squeeze(matrix(:,:,n));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;   
        elseif viewType == 2
            vol = squeeze(matrix(:,n,:));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;
        elseif viewType == 3
            vol = squeeze(matrix(n,:,:));
            imageSubset = vol(y-viewLength:y+viewLength, x-viewLength:x+viewLength);
            %noisereduc = imgaussfilt(imageSubset, 1);
            imshow(imageSubset,[]);
            drawnow;
        else
        end

    end


%%This function intializes standard threshholding analysis
    function standardThreshHoldInit()
        cd(firstDir)
        if viewType == 1
            standardThreshHold(squeeze(matrix(:,:,sliderPositon)));
        elseif viewType == 2
            standardThreshHold(squeeze(matrix(:,sliderPositon,:)));
        elseif viewType == 3
            standardThreshHold(squeeze(matrix(sliderPositon,:,:)));
        else
        end
    end

%% This function is used to view mark 1 when specific radius in calibration -- EL
    function viewMark1()
        n = mark1;
        if viewType == 1
            imshow(squeeze(matrix(:,:,n)),[]);
        elseif viewType == 2
            imshow(squeeze(matrix(:,n,:)),[]);
        elseif viewType == 3
            imshow(squeeze(matrix(n,:,:)),[]);
        end
        title(['Slice Number ' num2str(sliderPositon)])
        drawnow;
    end

%% This function is used to view mark 2 when specific radius in calibration -- EL
    function viewMark2()
        n = mark2;
        if viewType == 1
            imshow(squeeze(matrix(:,:,n)),[]);
        elseif viewType == 2
            imshow(squeeze(matrix(:,n,:)),[]);
        elseif viewType == 3
            imshow(squeeze(matrix(n,:,:)),[]);
        end
        title(['Slice Number ' num2str(sliderPositon)])
        drawnow;
    end



%% This function allows the user to switch the view between the calibrated and uncalibrated set of Dicome Files
    function switchImageSetStandardCal()
        cd(firstDir)
        [dirname]=uigetdir('Please choose dicom directory');
        filetype = questdlg('Have you used this set of DiCOM files before?', 'Choose One', 'Yes', 'No', 'Cancel');
        switch filetype
            case 'Yes'
                dataset = 2;
            case 'No'
                dataset = 1; 
        end

        if dataset == 1
            matrix = Generate3dMatrixCBCT(dirname);
            cd(dirname)
            save('PVmatrix.mat','matrix')
            save('ginfo.mat','ginfo1')
        elseif dataset == 2
            cd(dirname)
            load('PVmatrix.mat')
            load('ginfo.mat')

        end
        updateImage()
       
    end


%% UI Elements
f=figure(1);

%Slider to adjust view position.
slider = uicontrol('Parent',f,'Style','slider','Position',[81,390,420,40],'min',0, 'max',size(matrix,2), 'SliderStep', [1/size(matrix,2) 0.5]);

btn1 = uicontrol('Style', 'pushbutton', 'String', 'Mark 1','Position', [81,110,210,40],'Callback', @(hObject, event) setmark1(hObject, event));
btn2 = uicontrol('Style', 'pushbutton', 'String', 'Mark 2','Position', [291,110,210,40],'Callback', @(hObject, event) setmark2(hObject, event));

%View Switcher Buttons
viewSwitchAxial = uicontrol('Style', 'pushbutton', 'String', 'Axial View','Position', [81,350,140,40], 'Callback', @(hObject, event) switchViewAxialCallback(hObject, event));
viewSwitchSagittal = uicontrol('Style', 'pushbutton', 'String', 'Sagittal View','Position', [221,350,140,40], 'Callback', @(hObject, event) switchViewSagittalCallback(hObject, event));
viewSwitchCoronal = uicontrol('Style', 'pushbutton', 'String', 'Coronal View','Position', [361,350,140,40], 'Callback', @(hObject, event) switchViewCoronalCallback(hObject, event));

%Calibration Buttons
calibrateUsingAirAndWater = uicontrol('Style', 'pushbutton', 'String', ' Calibrate using Air and Water','Position', [81,310,210,40], 'Callback', @(hObject, event) initWaterAirCalibCallback(hObject, event));
calibrateUsingStandards = uicontrol('Style', 'pushbutton', 'String', 'Calibrate using Standards','Position', [291,310,210,40], 'Callback', @(hObject, event) initStandardCalibrationCallback(hObject, event));


uicontrol('Style', 'pushbutton', 'String', 'Hounsfield Unit Measurement','Position', [81,30,420,40],'Callback', @(hObject, event) takeMeasurementWithDistCallback(hObject, event));
uicontrol('Style', 'pushbutton', 'String', 'Grayscale Line Measurement','Position', [501,30,420,40],'Callback', @(hObject, event) takeLineMeasurementCallback(hObject, event));
%uicontrol('Style', 'pushbutton', 'String', 'Take Measurement','Position', [511,14,420,40],'Callback', @(hObject, event) takeMeasurementCallback(hObject, event));

initRun = uicontrol('Style', 'pushbutton', 'String', 'Grayscale Value Measurement','Position', [81,70,420,40],'Callback', @(hObject, event) takeMeasurement(hObject, event));
switchView = uicontrol('Style', 'pushbutton', 'String', 'Threshhold Test','Position', [81,150,420,40],'Callback', @(hObject, event) threshholdAnalysisCallback(hObject, event));

imageSetChange = uicontrol('Style', 'pushbutton', 'String', 'Change Image Set','Position', [81,270,420,40],'Callback', @(hObject, event) switchImageSetStandardCal());
getRadius = uicontrol('Style', 'pushbutton', 'String', 'Radius','Position', [81,230,420,40],'Callback', @(hObject, event) getradiusCallback(hObject, event));
mark2Center = uicontrol('Style', 'pushbutton', 'String', 'Select Pixel', 'Position', [81, 190, 420, 40], 'Callback', @(hObject, event) getpoint(hObject, event));

addlistener(slider,'ContinuousValueChange',@(hObject, event) updateImageCallback(hObject, event));

%dialogBox = ('Style', 
%display%
ax1=axes('parent',f,'position',[0.2 0.1 0.8 0.8]);
set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1]);
imshow(squeeze(matrix(:,:,n)),[]);

end
