close all
GSVnear = [1064 1364 1846];
GSVfar = [1268 1376 1682];
HU = [723 1447 2728];
plot(GSVnear, HU, 'o', GSVfar, HU, 'o')

hold on
coeff1 = polyfit(GSVnear, HU, 1);
y1 = coeff1(1) * GSVnear + coeff1(2);
plot(GSVnear,y1)
hold on
coeff2 = polyfit(GSVfar, HU, 1);
y2 = coeff2(1) * GSVfar + coeff2(2);
plot(GSVfar,y2)
legend('GSV near','GSV top of oral cavity','linear near','linear top of oral cavity')
xlabel('GSV')
ylabel('HU')
ylim([0 3500])