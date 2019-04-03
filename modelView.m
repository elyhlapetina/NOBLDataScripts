function modelView(matrix)

    sliderPositon = 0
    threeDimView = figure(2)
    figure(threeDimView)
    
    slider = uicontrol('Parent',threeDimView,'Style','slider','Position',[81,0,420,23],'min',0, 'max',5000);
    addlistener(slider,'ContinuousValueChange',@(hObject, event) updateImageCallback(hObject, event));
   
    
    function updateImageCallback(hObject,event)
        sliderPositon = (get(hObject,'Value'))
        updateImage();
    end

    function updateImage()
        
        cla('reset');
        p1 = patch(isosurface(matrix, sliderPositon),'FaceColor','blue',...
            'EdgeColor','none');
        %p2 = patch(isocaps(matrix, sliderPositon),'FaceColor','blue',...
        %    'EdgeColor','none');
        
        slider.Visible  = 'on'
        iso = isonormals(matrix,p1);
        view(3)
        axis tight
        daspect([1,1,1])
        colormap(gray(100))
        camlight left
        camlight
        lighting gouraud

        
    end



    
end

