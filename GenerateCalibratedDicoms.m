%Creates a new set of DICOM files that contain
%calibrate slope and rescale values

function directory = GenerateCalibratedDicoms(dirname,vol,type,RS, RI)
    
    global ginfo1 
    %intializes empty array to store images in,
    %the dimensions are (imagesize, imagesize, volume size)
    width = length(dicomread(char(strcat(dirname,'/',vol(1)))));
    
    
            
    olddirectory=(char(cd))
    for i = 1:length(vol)
        X{i} = dicomread(char(strcat(dirname,'/',vol(i))));
    end

    
    newDir = char(strcat(dirname, 'CalibratedScan',  type))
    mkdir(newDir)
    cd(newDir)
    indvar = 1;
    for i = 1:length(vol)
        if length(vol) <= 512
            if i <10;
                nameofdicom = sprintf('slice_00%d.dcm',i);
            elseif i>= 10 && i <100;
                nameofdicom = sprintf('slice_0%d.dcm',i);
            elseif i>=100;
                nameofdicom = sprintf('slice_%d.dcm',i);
            end
        end
        if length(vol) <= 1024
            if i <10;
                nameofdicom = sprintf('slice_000%d.dcm',i);
            elseif i>= 10 && i <100;
                nameofdicom = sprintf('slice_00%d.dcm',i);
            elseif i>=100 && i <1000;
                nameofdicom = sprintf('slice_0%d.dcm',i);
            elseif i>=1000;
                nameofdicom = sprintf('slice_%d.dcm',i);
            end
        end


        ginfo1{i}.RescaleSlope = RS;
        ginfo1{i}.RescaleIntercept = RI;
        S = ginfo1{i};
        dicomwrite(X{i}, nameofdicom, S, 'CreateMode', 'copy');

    end
    directory = newDir;
    "Finished"
    
end
