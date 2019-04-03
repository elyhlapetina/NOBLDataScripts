%Generates an ordered volume of DiCOM images based on given directory.
%Returns an array of DiCOM file names in order.
function volume = DICOM2VolumeCBCT(directory)
global ginfo1
%Changes directory.
cd(directory);

%Creates array of acquisition numbers based on unordered DiCOM files in
%directory.
if (directory ~= 0)
    loadingbar = waitbar(0,'Generating volume...');
    %dir gets all of the elements of the folder directory
    d = dir(directory);
    steps = length(d);
    step = 1;
    slices = [];
    
    
    for k = 1:size(d,1)
        %Checks if DiCOM file is present
        if strfind(d(k).name,'.dcm')>0
            %Here we are looking to see if any part of d(k).name has '.dcm'
            info = dicominfo(d(k).name);
            %slice_num = info.InstanceNumber;
            slice_num = info.InstanceNumber;
            %We're using the acquisitionNumber in the dicominfo to sort the
            %slices. 
            waitbar(step / steps)
            step = step + 1;
            %List of file name along with acquisition number
            slices = [slices; slice_num];
        end
    end
    close(loadingbar)
    
    loadingbar = waitbar(0,'Sorting...');
    
    %Sorts file names by acquisition numbers
    slices = sort(slices);
    vol = cell([1,length(slices)]);
    %Here the goal is to make the cellstr array 'vol' with all of the names
    %of the slices in order. 
    for k = 1:size(d,1)
        if strfind(d(k).name,'.dcm')>0
            inf1 = dicominfo(d(k).name);
            ind = find(slices==inf1.InstanceNumber);
            vol(ind)= cellstr(d(k).name);
            waitbar(info.InstanceNumber / steps)
            
        end
    end
    close(loadingbar)
    
    %Volume to be returned
    volume = vol;
end
 