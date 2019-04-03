clear all
[dirname] = uigetdir('*.csv','Please choose CSV directory');
cd(dirname)
[dirname] = uigetfile('*.csv','Please choose CSV directory');
M = csvread(dirname);
S1 = M(3:end,1);
S2 = M(3:end,2);
S3 = M(3:end,3);

S1Dist = fitdist(S1, 'Normal');
S2Dist = fitdist(S2, 'Normal');
S3Dist = fitdist(S3, 'Normal');

            
%%%%%%%%%%%%%%%%%%%%%%%%%%Values of EXPECTED standard values %%%%%%%%%%%%%%%%%%%%%%%%%%
HU1 = 2112;
HU2 = 4301.6;
HU3 = 6628.6;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count = 10000;
rescaleSlopeValues = [count];
rescaleInterceptValues = [count];
dmatValues = zeros(count,3);
f = figure(4);

loadingbar = waitbar(0,'Running Sim...');
for i = [1:count]
    
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

'RS mean'
mean(rescaleSlopeValues)
'RS std'
std(rescaleSlopeValues)
'RI mean'
mean(rescaleSlopeValues)
'RI std'
std(rescaleSlopeValues)

%subplot(2,1,1)
%{
for i = [1:count]

    
    waitbar(i / count)
    fixHU_lin = (dmatValues(i,:)*rescaleSlopeValues(i)) + rescaleInterceptValues(i);
    plot(dmatValues(i,:), fixHU_lin, 'r--')
    hold on
    plot(dmatValues(i,:), HounsfieldUnitmat, 'k+', 'MarkerSize', 15)
    
    
end
%}

close(loadingbar)
hold off
subplot(2,1,1)
histogram(rescaleSlopeValues)
subplot(2,1,2)
histogram(rescaleInterceptValues)
rescaleSlopeValues = rescaleSlopeValues.';
rescaleInterceptValues = rescaleInterceptValues.';

if size(rescaleSlopeValues) < size(rescaleInterceptValues)
    count = size(rescaleSlopeValues)
else
    count = size(rescaleInterceptValues)
end

dataWrite = [rescaleSlopeValues,rescaleInterceptValues]

dlmwrite('RS_LIN_VALS_test.csv',dataWrite,'roffset',1,'coffset',0,'-append');



