%Outputs expected HU of HA-HDPE standards or composition from wanted HU. 
%Can also determine theoretical density of standards with a known concentration 

clear
close all
evaltype = input('(1) HU vs. HA mass percent/HU to HA mass percent, (2) HA mass percent to density, (3) Lead(II) Nitrate samples\n');
keV = input('Enter the effective energy of the scanner in keV \n');

%Known variables: DHAp = density of HA particles, DHA = Density of HA
%within particles, Dair = density of air (also within particles, DHDPE =
%density of HDPE [g/cm^3]

DHAp = 1.67;
DHA = 3.1;
Dair = 0.001225;
DHDPE = 0.97;
DLeadNitrate = 4.53;


while keV ~= 20 && keV ~= 25.2 && keV ~= 31 && keV ~= 40 && keV ~= 50 && keV ~= 70 && keV ~= 80
    
    disp('invalid input')
    keV = input('Enter the effective energy of the scanner in keV (20/25.2/31/40/50/70/80) \n');
    
end

%Attenuation coefficients: Linear = [cm^-1], mass = [cm^2/g]
%Mass attenuation coefficients are gathered from the NIST website
%http://physics.nist.gov/PhysRefData/Xcom/html/xcom1.html
%Mass attenuation is multiplied by density to obtain linear coefficient

if keV == 20
    
    massuair = 0.7057;
    massuHA = 6.32;
    massuHDPE = 0.3751;
    massuLN = 52.84;
    massuwater = 0.7213;
    
elseif keV == 25.2
    
    massuair = 0.4234;
    massuHA = 3.235;
    massuHDPE = 0.2788;
    massuLN = 28.78;
    massuwater = 0.4386;
    
elseif keV == 31
    
    massuair = 0.2979;
    massuHA = 1.798;
    massuHDPE = 0.2364;
    massuLN = 16.7;
    massuwater = 0.314;
    
elseif keV == 40
    
    massuair = 0.2247;
    massuHA = 0.9068;
    massuHDPE = 0.2097;
    massuLN = 8.49;
    massuwater = 0.2395;
    
elseif keV == 50
    
    massuair = 0.1914;
    massuLN = 4.692;
    massuHDPE = 0.1965;
    massuHA = 0.5309;
    massuwater = 0.2076;
    
elseif keV == 70
    
    massuair = 0.1656;
    massuLN = 1.94;
    massuHDPE = 0.1824;
    massuHA = 0.282;
    massuwater = 0.1824;
    
elseif keV == 80
    
    massuair = 0.1589;    
    massuHA = 0.2345;   
    massuHDPE = 0.1773;    
    massuLN = 1.38;
    massuwater = 0.1755;
    
end

linearuwater = massuwater;
linearuair = massuair * Dair;

if evaltype == 1
    
    %Asks for concentrations of HA in standards and assigns sizes to
    %variables of interest.
    %M = mass [g], V = volume [cm^3], D = density [g/cm^3]
    %MHAp = input('enter the range of mass percentages of HAp\n');
    MHAp = 0:0.1:1;
    size = length(MHAp);
    MHA = zeros(1, size);
    Mair = zeros(1, size);
    MHDPE = zeros(1, size);
    
    VHAp = zeros(1, size);
    VHA = zeros(1, size);
    Vair = zeros(1, size);
    VHDPE = zeros(1, size);
    Vtot = zeros(1, size);
    
    DHAsoln = zeros(1, size);
    DHDPEsoln = zeros(1, size);
    Dairsoln = zeros(1, size);
    
    linearu = zeros(1, size);
    HU = zeros(1, size);
    
    %For each given composition of HAp (assuming 1 gram total), calculates 
    %volume and mass of HA and air in the HA particles. Then calculates 
    %the mass and volume of HDPE for each, as well as a total volume.
    %Next, it calculates the relative density of HA, HDPE, and air with
    %respect to the entire standard by dividing the mass of the component
    %of interest by the total volume. These relative densities are
    %multiplied by the known mass attenuation coefficients of each
    %component and the products are added together to obtain the linear
    %attenuation coefficient of each standard. The coefficient is then used
    %to find HU
    for i = 1:size
        
        VHAp(i) = MHAp(i) / DHAp;
        VHA(i) = (MHAp(i) - (Dair*VHAp(i))) / (DHA - Dair);
        Vair(i) = VHAp(i) - VHA(i);
        MHA(i) = DHA * VHA(i);
        Mair(i) = Dair * Vair(i);
        MHDPE(i) = 1 - MHAp(i);
        VHDPE(i) = MHDPE(i) / DHDPE;
        Vtot(i) = VHA(i) + Vair(i) + VHDPE(i) ;
        DHAsoln(i) = MHA(i) / Vtot(i);
        DHDPEsoln(i) = MHDPE(i) / Vtot(i);
        Dairsoln(i) = Mair(i) / Vtot(i);
        linearu(i) = (massuHA * DHAsoln(i)) + (massuHDPE * DHDPEsoln(i)) + (massuair * Dairsoln(i));
        HU(i) = 1000 * (linearu(i) - linearuwater) / (linearuwater - linearuair) ;
        
    end
    
    %Plots a graph of the theoretical HU values vs. the composition of HAp
    %for each standard
    plot(MHAp, HU, 'o')
    hold on
    title(['HU vs. mass percent HA at ' num2str(keV) ' keV'])
    xlabel('mass percent HA')
    ylabel('HU')
    %Asigns a fit to the graph. Can change to linear, quadratic, cubic, or
    %exponential.
    %p = polyfit(MHAp, HU, 1);
    p = polyfit(MHAp, HU, 2);
    %p = polyfit(MHAp, HU, 3);
    f1 = polyval(p, MHAp);
    plot(MHAp, f1, '-')
    %legend('HU', ['y = ' num2str(p(1)) 'x + ' num2str(p(2))], 'Location', 'northwest')
    legend('HU', ['y = ' num2str(p(1)) 'x^2 + ' num2str(p(2)) 'x + ' num2str(p(3))], 'Location', 'northwest')
    %legend('HU', ['y = ' num2str(p(1)) 'x^3 + ' num2str(p(2)) 'x^2 + ' num2str(p(3)) 'x + ' num2str(p(4))], 'Location', 'northwest')
    %MHAp = MHAp';
    %HU = HU';
    %p2 = fit(MHAp, HU, 'exp2');
    %plot(p2, MHAp, HU);
    
    %Uses the fit to work backwards from desired HU values to determine the
    %composition of standards that need to be created to get those HUs.
    DHU = input('Please insert desired HU values: [HU1, HU2, HU3,....]\n');
    p = polyfit(MHAp, HU, 1);
    HApw = (DHU - p(2)) / p(1);
    disp(HApw)
    
%Outputs expected density of a standard using the same steps as the 'for' loop above    
elseif evaltype == 2
    
    MHAp2 = input('Enter the composition that you want to make? (mass fraction of HA)\n');
    VHAp2 = MHAp2 / DHAp;
    VHA2 = (MHAp2 - (Dair*VHAp2)) / (DHA - Dair);
    Vair2 = VHAp2 - VHA2;
    MHA2 = DHA * VHA2;
    Mair2 = Dair * Vair2;
    MHDPE2 = 1 - MHAp2;
    VHDPE2 = MHDPE2 / DHDPE;
    Vtot2 = VHA2 + Vair2 + VHDPE2;
    ExpectedDensity = 1 / Vtot2;
    disp(ExpectedDensity)
    
elseif evaltype == 3
    
    %Asks for concentrations of HA in standards and assigns sizes to
    %variables of interest.
    %M = mass [g], V = volume [cm^3], D = density [g/cm^3]
    MLN = 0:0.02:0.2;
    size = length(MLN);
    Mwater = zeros(1, size);
    
    VLN = zeros(1, size);
    Vwater = zeros(1, size);
    Vtot = zeros(1, size);
    
    DLNsoln = zeros(1, size);
    Dwatersoln = zeros(1, size);
    
    linearu = zeros(1, size);
    HU = zeros(1, size);
    
    %For each given composition of HAp (assuming 1 gram total), calculates 
    %volume and mass of HA and air in the HA particles. Then calculates 
    %the mass and volume of HDPE for each, as well as a total volume.
    %Next, it calculates the relative density of HA, HDPE, and air with
    %respect to the entire standard by dividing the mass of the component
    %of interest by the total volume. These relative densities are
    %multiplied by the known mass attenuation coefficients of each
    %component and the products are added together to obtain the linear
    %attenuation coefficient of each standard. The coefficient is then used
    %to find HU
    for i = 1:size
        
        Mwater(i) = 1 - MLN(i);
        VLN(i) = MLN(i) / DLeadNitrate;
        Vwater(i) = Mwater(i);
        Vtot(i) = Vwater(i) + VLN(i);
        DLNsoln(i) = MLN(i) / Vtot(i);
        Dwatersoln(i) = Mwater(i) / Vtot(i);
        linearu(i) = (massuLN * DLNsoln(i)) + (massuwater * Dwatersoln(i));
        HU(i) = 1000 * (linearu(i) - linearuwater) / (linearuwater - linearuair) ;
        
    end
    
    plot(MLN, HU, 'o')
    hold on
    title(['HU vs. mass percent LN at ' num2str(keV) ' keV'])
    xlabel('mass percent LN')
    ylabel('HU')
    p = polyfit(MLN, HU, 1);
    f1 = polyval(p, MLN);
    plot(MLN, f1, '-')
    legend('HU', ['y = ' num2str(p(1)) 'x + ' num2str(p(2))], 'Location', 'northwest')
    DHU = input('Please insert desired HU values: [HU1, HU2, HU3,....]\n');
    LNw = (DHU - p(2)) / p(1);
    disp(LNw)
    
    
end



