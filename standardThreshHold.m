function  standardThreshHold(vol)
    imageSegmenter(vol)
    sliderPositon = 0
    threeDimView = figure(2)
    figure(threeDimView)
    
    slider = uicontrol('Parent',threeDimView,'Style','slider','Position',[81,0,420,23],'min',0, 'max',1);
    addlistener(slider,'ContinuousValueChange',@(hObject, event) updateImageCallback(hObject, event));
   
    
    function updateImageCallback(hObject,event)
        sliderPositon = (get(hObject,'Value'))
         updateImage();
    end

    function updateImage()
        
        sliderPositon = int16(sliderPositon);
        T = adaptthresh(vol,sliderPositon);
        BW = imbinarize(vol, T);
        imshow(BW);
        
        
    end


end
