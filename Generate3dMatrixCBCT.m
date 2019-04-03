%Generates of 3-dimenional array that represents scanned image in 3-d space
%Returns matrix of Grayscale value.

function matrix = Generate3dMatrixCBCT(dirnameOriginal);
global ginfo1
%Creates volume using DICOM2Volume
vol = DICOM2VolumeCBCT(dirnameOriginal);

%intializes empty array to store images in,
%the dimensions are (imagesize, imagesize, volume size)
width = length(dicomread(char(vol(1))));

%Ensures data type of unsigned integer.
dimensionalRep = zeros(width,width,length(vol),'int16');

loadingbar = waitbar(0,'Creating 3-D space...');

%Reads in one image, copies content (Grayscale Values) to 3-d matrix
for imageNumber = 1:length(vol)
    waitbar(imageNumber/length(vol));
    cd(dirnameOriginal);
    
    %Read in image
    currentImage = dicomread(char(vol(imageNumber)));
    %copy in the dicominfo data so that we can extract the Rescale slope
    %and intercept for HU conversion.
    
    ginfo1{imageNumber} = dicominfo(char(vol(imageNumber)));
    %Copy X,Y values to X,Y value of 3-d matrix.
    for x = 1:length(currentImage)
        for y = 1:length(currentImage);
%             dimensionalRep(y,x,imageNumber) = uint16(currentImage(y,x));
            dimensionalRep(y,x,imageNumber) = (currentImage(y,x));
        end
    end
end

close(loadingbar);

%Ensures unsigned integer datatype 
dimensionalRep1 = dimensionalRep;
%Addition by KV, tryig to figure out why some of the images aren't showing
%up. Maybe has to do with the uint16 command on the bottom turning all of
%the negative variables into zero. 
im2uint16(dimensionalRep);
ginfo1{1}
%return
matrix = dimensionalRep;
save('PVmatrix.mat', 'matrix')
save('ginfo.mat', 'ginfo1')
end
