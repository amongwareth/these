clear all

filenamemaster='~/Desktop/Google Drive/Encheres Elec/For Matlab/Exogenous_treated_03.2014/Vent/ExoVent_numeric.csv';
M = csvread(filenamemaster);

%%Keep only year of interest
yyyy=2011;
for i=1:size(M,1)
    if mod(i,10000)==0
        disp('y of interest'), disp(i)
    end
    if M(i,5)==yyyy&&(i==1||M(i-1,5)<yyyy)
        yi=i;
    end
    if M(i,5)==yyyy&&(i==size(M,1)||M(i+1,5)>yyyy)
        yf=i;
    end
end
Myyyy=M(yi:yf,:);
% clear M


kini=1;
kend=0;
lautocor=[];
for k=1:(size(Myyyy,1)-1)
    if mod(k,1000)==0
        k
    end
    if Myyyy(k,8)~=Myyyy(k+1,8 )
        kend=k;
        autocor=[];
        for i=kini:(kend-1)
            for j=(i+1):kend
                ertemp=abs(Myyyy(i,1)-Myyyy(j,1));
                disttemp=sqrt((Myyyy(i,9)-Myyyy(j,9))^2+(Myyyy(i,10)-Myyyy(j,10))^2);
                autocortemp=cat(2,disttemp,ertemp);
                autocor=cat(1,autocor,autocortemp);
            end
        end
        binranges=0:0.004:max(autocor(:,1));
        [bincounts,ind]=histc(autocor(:,1),binranges);
        autocor=cat(2,autocor,ind);
        A=sortrows(autocor,3);
        rini=1;
        rend=0;
        meanstd=[];
        for i=1:size(bincounts,1)
            if bincounts(i)>0
                rend=rend+bincounts(i);
                m1=mean(A(rini:rend,2));
                m2=mean(A(rini:rend,1));
                meantemp=cat(2,bincounts(i),m1,m2);
                meanstd=cat(1,meanstd,meantemp);
                rini=rend+1;
            end
        end

        y=meanstd(1:round(4/5*size(meanstd,1)),2);
        x=meanstd(1:round(4/5*size(meanstd,1)),3);
%         y=meanstd(:,2);
%         x=meanstd(:,3);
%         figure, plot(meanstd(2:size(meanstd,1),3),meanstd(2:size(meanstd,1),2))
        g = fittype('a*(1-exp(-x/b))','dependent',{'y'},'independent',{'x'},...
            'coefficients',{'a','b'});
        myfit=fit(x,y,g,'Lower',[0,0],'Upper',[10,0.3],'Startpoint', [4.5    0.04]);
        coefffit=coeffvalues(myfit);
%         figure, plot(myfit,meanstd(2:size(meanstd,1),3),meanstd(2:size(meanstd,1),2))
        kini=k+1;
        lautocortemp=cat(2,coefffit(2),Myyyy(k,5),Myyyy(k,6),Myyyy(k,7),Myyyy(k,8));
        lautocor=cat(1,lautocor,lautocortemp);
    end
end

% %%Convert lautocor to string to be stata friendly
dateseff=[];
for i=1:size(lautocor,1)
    if lautocor(i,4)<10
        dd=['0' num2str(lautocor(i,4))];
    else dd=num2str(lautocor(i,4));
    end
    if lautocor(i,3)<10
        mm=['0' num2str(lautocor(i,3))];
    else mm=num2str(lautocor(i,3));
    end
    if lautocor(i,5)<10
        hh=['0' num2str(lautocor(i,5))];
    else hh=num2str(lautocor(i,5));
    end
    dated=[dd '/' mm '/' num2str(lautocor(i,2))];
    datesefftemp={dated,hh,num2str(lautocor(i,1))};
    dateseff=cat(1,dateseff,datesefftemp); 
end 

%%Prepare the data to be written to .txt file
dateseff=dateseff;
fid = fopen(['/Users/alexisberges/Desktop/Google Drive/Encheres Elec/For Matlab/lautocor_' num2str(yyyy) '.txt'],'w');
fprintf(fid,'%s, %s, %s\n',dateseff{:,:});
fclose(fid);


%%%%%%%%%%%%%%% graph lautocor well
houra=[0;M(:,8)];
hourb=[M(:,8);0];
idxchange=find(houra-hourb);

lautocor=[];
hourlook=470;
kini=idxchange(hourlook);
kend=idxchange(hourlook+1)-1;
autocor=[];
k=1;
for i=kini:(kend-1)
    for j=(i+1):kend
        ertemp=abs(M(i,1)-M(j,1));
        disttemp=sqrt((M(i,9)-M(j,9))^2+(M(i,10)-M(j,10))^2)*6371;
        autocortemp=cat(2,disttemp,ertemp);
        autocor=cat(1,autocor,autocortemp);
    end
end
binranges=0:0.004*6371:max(autocor(:,1));
[bincounts,ind]=histc(autocor(:,1),binranges);
autocor=cat(2,autocor,ind);
A=sortrows(autocor,3);
rini=1;
rend=0;
meanstd=[];
for i=1:size(bincounts,1)
    if bincounts(i)>0
        rend=rend+bincounts(i);
        m1=mean(A(rini:rend,2));
        m2=mean(A(rini:rend,1));
        meantemp=cat(2,bincounts(i),m1,m2);
        meanstd=cat(1,meanstd,meantemp);
        rini=rend+1;
    end
end

y=meanstd(1:round(4/5*size(meanstd,1)),2);
x=meanstd(1:round(4/5*size(meanstd,1)),3);
%         y=meanstd(:,2);
%         x=meanstd(:,3);
%         figure, plot(meanstd(2:size(meanstd,1),3),meanstd(2:size(meanstd,1),2),'-','LineWidth',2)
g = fittype('a*(1-exp(-x/b))','dependent',{'y'},'independent',{'x'},...
    'coefficients',{'a','b'});
myfit=fit(x,y,g,'Lower',[0,0],'Upper',[10,0.3*6371],'Startpoint', [4.5    0.04*6371]);
coefffit=coeffvalues(myfit);
        figure
        plot1=plot(myfit,'r');
        set(plot1,'LineWidth',4)
        hold on
        plot2=plot(meanstd(2:size(meanstd,1),3),meanstd(2:size(meanstd,1),2),'b-+') ;
        set(plot2,'LineWidth',4)
        hold on
        plot3=plot(autocor(:,1),autocor(:,2),'ko','MarkerSize',2,'MarkerFaceColor',[0,0,0]);
        line1=line([0, 0.02*6371], [0,coefffit(1)/coefffit(2)*0.02*6371],'Color',[0 0 0],'LineStyle','--','LineWidth',2); 
        line2=line([0, 0.2*6371], [coefffit(1),coefffit(1)],'Color',[0 0 0],'LineStyle','--','LineWidth',2); 
        line3=line([coefffit(2), coefffit(2)], [0,coefffit(1)],'Color',[0 0.5 0],'LineStyle','--','LineWidth',2); 
        plotleg=legend([plot3 plot2 plot1 line1 line3],
                       {'Data from the pairs' 'Kernel smoothed data' 'Fitted exponential'
                       'Derivatives of the fitted curve at 0 and \infty' 'Autocorrelation lengthscale'},
                       'Location','northwest');
        set(plotleg,'FontSize',24);
kini=k+1;
lautocortemp=cat(2,coefffit(2),M(k,5),M(k,6),M(k,7),M(k,8));
lautocor=cat(1,lautocor,lautocortemp);













