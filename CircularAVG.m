% Averages GS values by location for specified volume / slice 
% Additionally returns matrix of GSVs from slice ROI
% @param: slice indicates the slice number for functioncal
% @param: radius represents the number of pixels from central point that 
%         will be used to calculate the average
%

function [sliceAverage,returnSingleValueArray] = CircularAVG(slice, radius, locationX, locationY,pixel_reduc)

slice = int32(slice);
sizerow = size(slice,1);
sizecol = size(slice,2);
sizeL=1;
if(sizerow > sizecol)
    sizeL = sizerow;
else
    sizeL = sizecol;
end
%Calculates distance at each index
distanceMatrix = zeros(sizerow, sizecol);

for i = 1:sizerow
    for j = 1:sizecol
        
        distanceMatrix(i,j) = sqrt(double(((locationX) -i).^2 + ((locationY)-j).^2));
    end
end

singleValueCount = 0;


for i = 1:sizerow
    for j = 1:sizecol
        if (distanceMatrix(i,j) < radius)
            singleValueCount = singleValueCount + 1;
        end
    end
end
singleValueArray = [singleValueCount];        
        
    
valueCount = int32(zeros(sizeL, 3));

currentIndex = 1;
continueOn = true;
tolerance = 2;
%%Checking if the point chosen is less than the radius

singleValueArrayIndex = 1;

for i = 1:sizerow
    for j = 1:sizecol
        r = 1;
        continueOn = true;
        
        if (distanceMatrix(i,j) <= radius - pixel_reduc) %includes images within radius
            singleValueArrayIndex = singleValueArrayIndex + 1 ;
            singleValueArray(singleValueArrayIndex) = slice(i,j);
            while r < length(valueCount) && continueOn==true
                
                %checks if there a new entry
                if valueCount(r,1) == 0
                    valueCount(currentIndex,1) = distanceMatrix(i,j);
                    valueCount(currentIndex,2) = 1;
                    valueCount(currentIndex,3) = slice(i,j);
                    currentIndex = currentIndex + 1;
                    continueOn = false;
                    %checks if it is valid to add to entry
                elseif abs(valueCount(r,1) - distanceMatrix(i,j)) < tolerance
                    valueCount(r,2) =  valueCount(r,2) + 1;
                    valueCount(r,3) = (valueCount(r,3) + slice(i,j)) / 2;
                    continueOn = false;
                    %increments to next entry
                else
                    r = r+1;
                end
            end
        end
    end
    
end

%%%%%%Prepares data for Analysis%%%%%%%%%%%%
%counts all non-zero data
count = 0;
for p = 1: length(valueCount)
    if valueCount(p,1) ~= 0
        count = count + 1;
    end
end

%copy calculated values into new plots up to calculated count
numOccurances = [count];
distances = [count];
averages = [count];
averages = int32(averages);
for p = 1:count
    numOccurances(p) = valueCount(p,2); %num occurances
    distances(p) = valueCount(p,1); %distances
    averages(p) = valueCount(p,3); %average
end
global valuCount
valuCount = valueCount;
sliceAverage = mean2(averages);
returnSingleValueArray = singleValueArray;

end


