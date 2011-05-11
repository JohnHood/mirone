function varargout = diluvio(varargin)
% Simulate the effect of sea-level variation on DEMs 

%	Copyright (c) 2004-2011 by J. Luis
%
% 	This program is part of Mirone and is free software; you can redistribute
% 	it and/or modify it under the terms of the GNU Lesser General Public
% 	License as published by the Free Software Foundation; either
% 	version 2.1 of the License, or any later version.
% 
% 	This program is distributed in the hope that it will be useful,
% 	but WITHOUT ANY WARRANTY; without even the implied warranty of
% 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% 	Lesser General Public License for more details.
%
%	Contact info: w3.ualg.pt/~jluis/mirone
% --------------------------------------------------------------------

	if isempty(varargin)	return,		end

	hObject = figure('Vis','off');
	diluvio_LayoutFcn(hObject);
	handles = guihandles(hObject);     
	handMir = varargin{1};
	move2side(handMir.figure1, hObject, 'right')

	if ( ~(handMir.head(5) < 0 && handMir.head(6) > 0) )
		warndlg('The grid Z values do not span both above and below zero. Result is undetermined.','Warning')
	end
	Z = getappdata(handMir.figure1,'dem_z');
	if (~isempty(Z))
		handles.have_nans = handMir.have_nans;
		handles.z_min = handMir.head(5);
		handles.z_max = handMir.head(6);
		handles.z_min_orig = handles.z_min;
		handles.z_max_orig = handles.z_max;
	else
		warndlg('Grid was not stored in memory. Quiting','Warning')
		delete(hObject);        return
	end
	handles.hAxesMir = handMir.axes1;
	handles.hImgMir = handMir.hImg;
	zz = scaleto8(Z,16);
	set(handles.hImgMir,'CData',zz,'CDataMapping','scaled')

	handles.hMirFig = handMir.figure1;
	cmap_orig = get(handles.hMirFig,'Colormap');
	dz = handles.z_max - handles.z_min;
	%cmap = interp1(1:size(cmap_orig,1),cmap_orig,linspace(1,size(cmap_orig,1),round(dz)));
	handles.cmap = cmap_orig;
	handles.cmap_original = cmap_orig;
	set(handles.figure1,'ColorMap',cmap_orig);      I = 1:length(cmap_orig);
	image(I(end:-1:1)','Parent',handles.axes1);
	set(handles.axes1,'YTick',[],'XTick',[]);

	% Add this figure handle to the carra?as list
	plugedWin = getappdata(handles.hMirFig,'dependentFigs');
	plugedWin = [plugedWin hObject];
	setappdata(handles.hMirFig,'dependentFigs',plugedWin);
	
	% Try to position this figure glued to the right of calling figure
	posThis = get(hObject,'Pos');
	posParent = get(handles.hMirFig,'Pos');
	ecran = get(0,'ScreenSize');
	xLL = posParent(1) + posParent(3) + 6;
	xLR = xLL + posThis(3);
	if (xLR > ecran(3))         % If figure is partially out, bring totally into screen
        xLL = ecran(3) - posThis(3);
	end
	yLL = (posParent(2) + posParent(4)/2) - posThis(4) / 2;
	set(hObject,'Pos',[xLL yLL posThis(3:4)])

	% Set the slider to the position corresponding to Z = 0
	set(handles.slider_zeroLevel,'Min',handles.z_min,'Max',handles.z_max,'Value',0)
	set(handles.slider_zeroLevel,'SliderStep',[1 10]/dz)
	
	val_cor = round((0 - handles.z_min) / dz * size(handles.cmap,1));
	handles.cmap = [repmat([0 0 1],val_cor,1); handles.cmap_original(val_cor+1:end,:)];
	set(handles.figure1,'ColorMap',handles.cmap)
	set(handles.hMirFig,'Colormap',handles.cmap)
	
	guidata(hObject, handles);	
	set(hObject,'Vis','on')
	if (nargout),	varargout{1} = hObject;		end

% -----------------------------------------------------------------------------------
function slider_zeroLevel_CB(hObject, handles)
	val = get(hObject,'Value');
	val_cor = round((val - handles.z_min) / (handles.z_max - handles.z_min) * size(handles.cmap,1));
	handles.cmap = [repmat([0 0 1],val_cor,1); handles.cmap_original(val_cor+1:end,:)];
	set(handles.figure1,'ColorMap',handles.cmap)
	set(handles.hMirFig,'ColorMap',handles.cmap)
	set(handles.text_zLevel,'String',num2str(val))
	guidata(handles.figure1,handles)

% -----------------------------------------------------------------------------------
function edit_zMin_CB(hObject, handles)
    xx = str2double(get(hObject,'String'));
    if (isnan(xx)),     set(hObject,'String','0');  end

% -----------------------------------------------------------------------------------
function edit_zMax_CB(hObject, handles)
    xx = str2double(get(hObject,'String'));
    if (isnan(xx)),     set(hObject,'String','50');  end

% -----------------------------------------------------------------------------------
function edit_zStep_CB(hObject, handles)
    xx = str2double(get(hObject,'String'));
    if (isnan(xx)),     set(hObject,'String','1');  end

% -----------------------------------------------------------------------------------
function edit_frameInterval_CB(hObject, handles)
    xx = str2double(get(hObject,'String'));
    if (isnan(xx)),     set(hObject,'String','1');  end

% -----------------------------------------------------------------------------------
function push_run_CB(hObject, handles)
    zMin = round(str2double(get(handles.edit_zMin,'String')));
    zMax = round(str2double(get(handles.edit_zMax,'String')));
    dt = str2double(get(handles.edit_frameInterval,'String'));
    zStep = round(str2double(get(handles.edit_zStep,'String')));
    zStep = zStep * sign(zMax);     % For going either up or down
    
    for (z = zMin:zStep:zMax)
    	val_cor = round((z - handles.z_min) / (handles.z_max - handles.z_min) * length(handles.cmap));
	    handles.cmap = [repmat([0 0 1],val_cor,1); handles.cmap_original(val_cor+1:end,:)];
	    set(handles.figure1,'ColorMap',handles.cmap)
	    set(handles.hMirFig,'ColorMap',handles.cmap)
    	set(handles.text_zLevel,'String',sprintf('%d',z))
    	set(handles.slider_zeroLevel,'Value',z)
        pause(dt)
    end
    
%-------------------------------------------------------------------------------------
function figure1_KeyPressFcn(hObject, eventdata)
	if isequal(get(hObject,'CurrentKey'),'escape')
        delete(hObject);
	end


% --- Creates and returns a handle to the GUI figure. 
function diluvio_LayoutFcn(h1)

set(h1,...
'PaperUnits',get(0,'defaultfigurePaperUnits'),...
'Color',get(0,'factoryUicontrolBackgroundColor'),...
'KeyPressFcn',{@figure1_KeyPressFcn},...
'MenuBar','none',...
'Name','NOE Deluge',...
'NumberTitle','off',...
'Position',[520 456 141 344],...
'RendererMode','manual',...
'Resize','off',...
'HandleVisibility','callback',...
'Tag','figure1');

uicontrol('Parent',h1,'Position',[70 29 61 311],'Style','frame');

axes('Parent',h1,...
'Units','pixels',...
'CameraPosition',[0.5 0.5 9.16025403784439],...
'CameraPositionMode',get(0,'defaultaxesCameraPositionMode'),...
'Color',get(0,'defaultaxesColor'),...
'ColorOrder',get(0,'defaultaxesColorOrder'),...
'Position',[30 29 30 311],...
'Tag','axes1');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@diluvio_uiCB,...
'Position',[7 29 15 311],...
'Style','slider',...
'SliderStep',[0.001 0.05],...
'Tag','slider_zeroLevel');

 uicontrol('Parent',h1,...
'Units','characters',...
'FontSize',10,...
'FontWeight','bold',...
'Position',[1.8 0.384615384615385 14.2 1.23076923076923],...
'String','0',...
'Style','text',...
'Tag','text_zLevel');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@diluvio_uiCB,...
'Position',[84 281 30 21],...
'String','0',...
'Style','edit',...
'TooltipString','Starting value of sea level',...
'Tag','edit_zMin');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@diluvio_uiCB,...
'Position',[84 230 30 21],...
'String','50',...
'Style','edit',...
'TooltipString','Maximum height of flooding',...
'Tag','edit_zMax');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@diluvio_uiCB,...
'Position',[85 179 30 21],...
'String','1',...
'Style','edit',...
'TooltipString','Height step for flooding',...
'Tag','edit_zStep');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@diluvio_uiCB,...
'Position',[85 129 30 21],...
'String','1',...
'Style','edit',...
'TooltipString','Time interval between frames (seconds)',...
'Tag','edit_frameInterval');

uicontrol('Parent',h1,...
'Enable','off',...
'Position',[81 42 48 15],...
'String','Movie',...
'Style','checkbox',...
'TooltipString','Check this to create a movie',...
'Tag','checkbox_movie');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[76 302 51 15],...
'String','Start level',...
'Style','text');

uicontrol('Parent',h1,...
'HorizontalAlignment','left',...
'Position',[77 251 51 15],...
'String','End level',...
'Style','text');

uicontrol('Parent',h1,...
'Position',[85 201 31 15],...
'String','Dz',...
'Style','text');

uicontrol('Parent',h1,...
'Position',[85 151 31 15],...
'String','Dt',...
'Style','text');

uicontrol('Parent',h1,...
'Call',@diluvio_uiCB,...
'Position',[81 74 40 21],...
'String','Run',...
'TooltipString','Run the Noe deluge',...
'Tag','push_run');

function diluvio_uiCB(hObject, eventdata)
% This function is executed by the callback and than the handles is allways updated.
	feval([get(hObject,'Tag') '_CB'],hObject, guidata(hObject));
