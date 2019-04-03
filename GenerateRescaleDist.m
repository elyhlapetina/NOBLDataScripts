%Takes a matrix with sets of measured grayscale values for each of the
%standards. A guassian distribution is calcuated for each of the standards.
%A random number from each gaussian is choosen and a linear fit is created,
%this is done "count" times. A CSV file is writen with each pair of slope
%and intercept values.

% Vol:
        %Matrix containing grayscale values for each standard. Column 1 is S1
        % Column 2 is S2 and so on...
% HU1:
        %Expected Hounsfield Unit for Standard 1
% HU2
        %Expected Hounsfield Unit for Standard 2
% HU3
        %Expected Hounsfield Unit for Standard 3
% HU4
        %Expected Hounsfield Unit for Standard 4
% Dirnames
        %Director for file to be saved.

function GenerateRescaleDist(vol,HU1,HU2,HU3,HU4,dirname)
    
    %Number of RS/RI combintations to be computed.
    count = 100000;
    %Measured grayscale values for each standard (respectively S1 -> S3)
    %S4 is only calculated if a number is passed.
    S1 = vol(3:end,1);
    S2 = vol(3:end,2);
    
    S1Dist = fitdist(S1, 'Normal');
    S2Dist = fitdist(S2, 'Normal');

    if ~isnan(HU3)
        S3 = vol(3:end,3);
        S3Dist = fitdist(S3, 'Normal');
    end
   

    if ~isnan(HU4)
        S4 = vol(3:end,3);
        S4Dist = fitdist(S4, 'Normal');
    end

    
    %Pre-defiens sizes for each struct containing RS and RI values.
    rescaleSlopeValues = [count];
    rescaleInterceptValues = [count];
    
    if isnan(HU4) && isnan(HU3)
        dmatValues = zeros(count,2);
    elseif isnan(HU4)
        dmatValues = zeros(count,3);
    else
        dmatVlaues = zeros(count,4);
    end
    
    
    f = figure(4);
    loadingbar = waitbar(0,'Running Sim...');
    
    %Based on if Standrd 4 is present, the machine will pick 1 random
    %number from each gaussian, create a linear best-fit andsave the slope
    %and intercept of the best fit to the RI / RS structs respectively.
    %Best fit is computed based on expected HU values.
    if isnan(HU4) && isnan(HU3)
        parfor i = [1:count]
            waitbar(i / count)
            S1Rand = random(S1Dist);
            S2Rand = random(S2Dist);

            HounsfieldUnitmat = [HU1;HU2;];
            Dmat = [S1Rand; S2Rand;];

            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            RS_lin = rescale(1);
            RI_lin = rescale(2);

            rescaleSlopeValues(i) = RS_lin;
            rescaleInterceptValues(i) = RI_lin;
            dmatValues(i,:) = Dmat;
        end
    
    elseif isnan(HU4)
        parfor i = [1:count]
            waitbar(i / count)
            S1Rand = random(S1Dist);
            S2Rand = random(S2Dist);
            S3Rand = random(S3Dist);

            HounsfieldUnitmat = [HU1;HU2;HU3;];
            Dmat = [S1Rand; S2Rand; S3Rand;];

            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            RS_lin = rescale(1);
            RI_lin = rescale(2);

            rescaleSlopeValues(i) = RS_lin;
            rescaleInterceptValues(i) = RI_lin;
            dmatValues(i,:) = Dmat;
        end
        
    else
        parfor i = [1:count]
            waitbar(i / count)
            S1Rand = random(S1Dist);
            S2Rand = random(S2Dist);
            S3Rand = random(S3Dist);
            S4Rand = random(S4Dist);

            HounsfieldUnitmat = [HU1;HU2;HU3;HU4;];
            Dmat = [S1Rand; S2Rand; S3Rand; S4Rand;];

            rescale = polyfit(Dmat, HounsfieldUnitmat, 1);
            RS_lin = rescale(1);
            RI_lin = rescale(2);

            rescaleSlopeValues(i) = RS_lin;
            rescaleInterceptValues(i) = RI_lin;
            dmatValues(i,:) = Dmat;
        end
    end

    
    cd(dirname)
    
    %Displays data.
    close(loadingbar)
    hold off
    subplot(2,1,1)
    histogram(rescaleSlopeValues)
    title('Rescale Slope Values')
    subplot(2,1,2)
    histogram(rescaleInterceptValues)
    title('Rescale Intercept Values')
    rescaleSlopeValues = rescaleSlopeValues.';
    rescaleInterceptValues = rescaleInterceptValues.';
    
    dataWrite = [rescaleSlopeValues,rescaleInterceptValues]

    %Writes CSV
    dlmwrite('RS_LIN_VALS_test.csv',dataWrite,'roffset',1,'coffset',0,'-append');



end
