function varargout = deform_mansinha(varargin)
% M-File changed by desGUIDE 
% varargin   command line arguments to deform_mansinha (see VARARGIN) 

%	Copyright (c) 2004-2006 by J. Luis
%
%	This program is free software; you can redistribute it and/or modify
%	it under the terms of the GNU General Public License as published by
%	the Free Software Foundation; version 2 of the License.
%
%	This program is distributed in the hope that it will be useful,
%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%	GNU General Public License for more details.
%
%	Contact info: w3.ualg.pt/~jluis/mirone
% --------------------------------------------------------------------

hObject = figure('Tag','figure1','Visible','off');
handles = guihandles(hObject);
guidata(hObject, handles);
deform_mansinha_LayoutFcn(hObject,handles);
handles = guihandles(hObject);
 
movegui(hObject,'east');
set(hObject,'Name','Vertical elastic deformation');
handles.h_calling_fig = [];     % Handles to the calling figure

if ~isempty(varargin)
    h_fig = varargin{1};
    handles.h_fault = varargin{2};
    handles.FaultStrike = varargin{3};
    handles.geog = varargin{4};
else
    delete(hObject)
    return
end

handles.n_faults = length(handles.h_fault);
if (handles.n_faults > 1)
    set(handles.popup_fault,'String',cellstr(num2str(1:handles.n_faults,'%.0f')'))
    set(handles.h_fault(1),'LineStyle','--');   % set the top fault one with a dashed line type
    refresh(h_fig);         % otherwise, ML BUG
else
    set(handles.popup_fault,'Visible','off')
    delete(findobj(hObject,'Style','text','Tag','fault_number'))    % Otherwise it would reborn in Pro look
end

fault_x = get(handles.h_fault,'XData');     fault_y = get(handles.h_fault,'YData');
if (handles.n_faults > 1)
    for (k=1:handles.n_faults)  nvert(k) = size(fault_x{k},2) - 1;  end
else
    nvert = size(fault_x,2) - 1;
end
handles.Mw(1:handles.n_faults) = 0;

if (any(nvert > 1))
    set(handles.popup_segment,'Visible','on');    S = [];
    % Even if we have more than one fault, the segments popup will start with only the first fault's segments
    for (i=1:nvert(1))     S = [S; ['Segment ' num2str(i)]];   end
    set(handles.popup_segment,'String',cellstr(S))
else
    set(handles.popup_segment,'Visible','off')
    delete(findobj(hObject,'Style','text','Tag','fault_segment'))    % Otherwise it would reborn in Pro look
end

handles.fault_x = fault_x;
handles.fault_y = fault_y;
handles.nvert = nvert;
handles.hide_planes(1:handles.n_faults) = 0;
handles.dms_xinc = 0;           handles.dms_yinc = 0;
handles.one_or_zero = 1;        % For Grid Registration grids, which are the most common cases

handles.FaultLength = LineLength(handles.h_fault,handles.geog);
% Make them all cell arrays to simplify logic
if (~iscell(handles.FaultLength))   handles.FaultLength = {handles.FaultLength};   end
if (~iscell(handles.FaultStrike))   handles.FaultStrike = {handles.FaultStrike};   end
if (~iscell(handles.fault_x))       handles.fault_x = {handles.fault_x};    handles.fault_y = {handles.fault_y};   end
handles.DislocStrike = handles.FaultStrike;

for (k=1:handles.n_faults)
	handles.FaultDip{k}(1:nvert(k)) = 45;       handles.FaultWidth{k}(1:nvert(k)) = NaN;
	handles.FaultDepth{k}(1:nvert(k)) = NaN;	handles.FaultTopDepth{k}(1:nvert(k)) = 0;
	handles.DislocSlip{k}(1:nvert(k)) = NaN;	handles.DislocRake{k}(1:nvert(k)) = NaN;
end

z1 = num2str(handles.FaultLength{1}(1));    z2 = num2str(handles.FaultStrike{1}(1),'%.1f');
z3 = num2str(handles.FaultDip{1}(1),'%.1f');
set(handles.edit_FaultLength,'String',z1,'Enable','off')
set(handles.edit_FaultStrike,'String',z2,'Enable','off')
set(handles.edit_FaultDip,'String',z3)
set(handles.edit_DislocStrike,'String',z2)
set(handles.edit_DislocSlip,'String','')
set(handles.edit_DislocRake,'String','')

% Default the top depth fault to zero
set(handles.edit_FaultTopDepth,'String','0')

%-----------
% Fill in the grid limits boxes (in case user wants to compute a grid)
% But also try to guess if we are dealing with other (m or km) than geogs
head = getappdata(h_fig,'GMThead');
handles.is_meters = 0;     handles.is_km = 0;   handles.um_milhao = 1e6;
if (~isempty(head))
    if (~handles.geog)      % Try to guess if user units are km or meters
        dx = head(2) - head(1);   dy = head(4) - head(3);
        len = sqrt(dx.*dx + dy.*dy);         % Distance in user unites
        if (len > 1e5)      % If grid's diagonal > 1e5 consider we have meters
            handles.is_meters = 1;     handles.is_km = 0;   handles.um_milhao = 1e3;
            set(handles.popup_GridCoords,'Value',2)
        else
            handles.is_meters = 0;     handles.is_km = 1;
            set(handles.popup_GridCoords,'Value',3)
        end
    end
else
    delete(hObject);    return
end
x1 = num2str(head(1),'%.10f');      x2 = num2str(head(2),'%.10f');
y1 = num2str(head(3),'%.10f');      y2 = num2str(head(4),'%.10f');
% But remove any possible trailing zeros
x1 = ddewhite(x1,'0');              x2 = ddewhite(x2,'0');
y1 = ddewhite(y1,'0');              y2 = ddewhite(y2,'0');
set(handles.edit_Xmin,'String',x1); set(handles.edit_Xmax,'String',x2)
set(handles.edit_Ymin,'String',y1); set(handles.edit_Ymax,'String',y2)
handles.x_min = head(1);            handles.x_max = head(2);
handles.y_min = head(3);            handles.y_max = head(4);

[m,n] = size(getappdata(h_fig,'dem_z'));

% Fill in the x,y_inc and nrow,ncol boxes
set(handles.edit_Nrows,'String',num2str(m))
set(handles.edit_Ncols,'String',num2str(n))

% Compute default xinc, yinc based on map limits
yinc = (head(4) - head(3)) / (m-1);   xinc = (head(2) - head(1)) / (n-1);
set(handles.edit_Yinc,'String',num2str(yinc,10))
set(handles.edit_Xinc,'String',num2str(xinc,10))
%-----------

handles.nrows = m;      handles.ncols = n;
handles.x_inc = xinc;   handles.y_inc = yinc;
handles.h_calling_fig = h_fig;

%------------ Give a Pro look (3D) to the frame boxes  -------------------------------
bgcolor = get(0,'DefaultUicontrolBackgroundColor');
framecolor = max(min(0.65*bgcolor,[1 1 1]),[0 0 0]);
set(0,'Units','pixels');    set(hObject,'Units','pixels')    % Pixels are easier to reason with
h_f = findobj(hObject,'Style','Frame');
for i=1:length(h_f)
    frame_size = get(h_f(i),'Position');
    f_bgc = get(h_f(i),'BackgroundColor');
    usr_d = get(h_f(i),'UserData');
    if abs(f_bgc(1)-bgcolor(1)) > 0.01           % When the frame's background color is not the default's
        frame3D(hObject,frame_size,framecolor,f_bgc,usr_d)
    else
        frame3D(hObject,frame_size,framecolor,'',usr_d)
        delete(h_f(i))
    end
end
% Recopy the text fields on top of previously created frames (uistack is to slow)
h_t = findobj(hObject,'Style','Text');
for i=1:length(h_t)
    usr_d = get(h_t(i),'UserData');
    t_size = get(h_t(i),'Position');   t_str = get(h_t(i),'String');    fw = get(h_t(i),'FontWeight');
    bgc = get (h_t(i),'BackgroundColor');   fgc = get (h_t(i),'ForegroundColor');
    t_just = get(h_t(i),'HorizontalAlignment');     t_tag = get (h_t(i),'Tag');
    uicontrol('Parent',hObject, 'Style','text', 'Position',t_size,'String',t_str,'Tag',t_tag,...
        'BackgroundColor',bgc,'ForegroundColor',fgc,'FontWeight',fw,...
        'UserData',usr_d,'HorizontalAlignment',t_just);
end
delete(h_t)
%------------- END Pro look (3D) -------------------------------------------------------

handles.h_txt_Mw = findobj(hObject,'Style','Text','Tag','text_Mw');
handles.txt_Mw_pos = get(handles.h_txt_Mw,'Position');

% Choose default command line output for deform_mansinha_export
handles.output = hObject;
guidata(hObject, handles);
set(hObject,'Visible','on');

% ------------------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = deform_mansinha_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

% ------------------------------------------------------------------------------------
function edit_FaultLength_Callback(hObject, eventdata, handles)
% Cannot be changed

% ------------------------------------------------------------------------------------
function edit_FaultWidth_Callback(hObject, eventdata, handles)
% Actualize the "FaultWidth" field
xx = str2double(get(hObject,'String'));
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
if (xx < 0)         % If user tried to give a negative width
    xx = -xx;
    set(hObject,'String',num2str(xx))
end
dip = str2double(get(handles.edit_FaultDip,'String'));
top_d = str2double(get(handles.edit_FaultTopDepth,'String'));
depth = top_d + xx * cos((90-dip)*pi/180);
set(handles.edit_FaultDepth,'String',num2str(depth));
seg = get(handles.popup_segment,'Value');
handles.FaultWidth{fault}(seg) = xx;
handles.FaultDepth{fault}(seg) = depth;

% Update the patch that represents the surface projection of the fault plane
xx = [handles.fault_x{fault}(seg); handles.fault_x{fault}(seg+1)];
yy = [handles.fault_y{fault}(seg); handles.fault_y{fault}(seg+1)];

D2R = pi / 180;
off = handles.FaultWidth{fault}(seg) * cos(handles.FaultDip{fault}(seg)*D2R);
strk = handles.FaultStrike{fault}(seg);

if (handles.geog)
    rng = off / 6371 / D2R;
    [lat1,lon1] = circ_geo(yy(1),xx(1),rng,strk+90,1);
    [lat2,lon2] = circ_geo(yy(2),xx(2),rng,strk+90,1);
else
    if (handles.is_meters)  off = off * 1e3;    end
    lon1 = xx(1) + off * cos(strk*D2R);     lon2 = xx(2) + off * cos(strk*D2R);
    lat1 = yy(1) - off * sin(strk*D2R);     lat2 = yy(2) - off * sin(strk*D2R);
end
x = [xx(1) xx(2) lon2 lon1];    y = [yy(1) yy(2) lat2 lat1];
hp = getappdata(handles.h_fault(fault),'PatchHand');
try,    set(hp(seg),'XData',x,'YData',y,'FaceColor',[.8 .8 .8],'EdgeColor','k','LineWidth',1);  end

% Compute Moment magnitude
M0 = 3e10 * handles.um_milhao * handles.DislocSlip{fault}(:) .* handles.FaultWidth{fault}(:) .* ...
    str2double(get(handles.edit_FaultLength,'String'));
if (length(M0) > 1)     M0 = sum(M0);   end
mag = 2/3*(log10(M0) - 9.1);
if (~isnan(mag))
    txt = ['Moment Magnitude = ' num2str(mag,'%.1f')];
    set(handles.h_txt_Mw,'String',txt,'Position',handles.txt_Mw_pos + [0 0 30 0])
    handles.Mw(fault) = mag;
end

guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_FaultStrike_Callback(hObject, eventdata, handles)
% Cannot be changed

% ------------------------------------------------------------------------------------
function edit_FaultDip_Callback(hObject, eventdata, handles)
% Actualize the "FaultDip" field
xx = str2double(get(hObject,'String'));
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
top_d = str2double(get(handles.edit_FaultTopDepth,'String'));
W = str2double(get(handles.edit_FaultWidth,'String'));
depth = top_d + W * cos((90-xx)*pi/180);
set(handles.edit_FaultDepth,'String',num2str(depth));
seg = get(handles.popup_segment,'Value');
handles.FaultDip{fault}(seg) = xx;
handles.FaultDepth{fault}(seg) = depth;

% Update the patch that represents the surface projection of the fault plane
xx = [handles.fault_x{fault}(seg); handles.fault_x{fault}(seg+1)];
yy = [handles.fault_y{fault}(seg); handles.fault_y{fault}(seg+1)];

D2R = pi / 180;
off = handles.FaultWidth{fault}(seg) * cos(handles.FaultDip{fault}(seg)*D2R);
strk = handles.FaultStrike{fault}(seg);

if (handles.geog)
    rng = off / 6371 / D2R;
    [lat1,lon1] = circ_geo(yy(1),xx(1),rng,strk+90,1);
    [lat2,lon2] = circ_geo(yy(2),xx(2),rng,strk+90,1);
else
    if (handles.is_meters)  off = off * 1e3;    end
    lon1 = xx(1) + off * cos(strk*D2R);     lon2 = xx(2) + off * cos(strk*D2R);
    lat1 = yy(1) - off * sin(strk*D2R);     lat2 = yy(2) - off * sin(strk*D2R);
end
x = [xx(1) xx(2) lon2 lon1];    y = [yy(1) yy(2) lat2 lat1];
hp = getappdata(handles.h_fault(fault),'PatchHand');
try,    set(hp(seg),'XData',x,'YData',y,'FaceColor',[.8 .8 .8],'EdgeColor','k','LineWidth',1);  end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_FaultDepth_Callback(hObject, eventdata, handles)
% Actualize the "FaultTopDepth" field
xx = str2double(get(hObject,'String'));
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
if (xx < 0)         % If user tried to give a negative depth
    xx = -xx;
    set(hObject,'String',num2str(xx))
end
W = str2double(get(handles.edit_FaultWidth,'String'));
dip = str2double(get(handles.edit_FaultDip,'String'));
top_d = xx - W * cos((90-dip)*pi/180);
set(handles.edit_FaultTopDepth,'String',num2str(top_d));
seg = get(handles.popup_segment,'Value');
handles.FaultDepth{fault}(seg) = xx;
handles.FaultTopDepth{fault}(seg) = top_d;
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_FaultTopDepth_Callback(hObject, eventdata, handles)
% Actualize the "FaultDepth" field
xx = str2double(get(hObject,'String'));
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
if (xx < 0)         % If user tried to give a negative depth
    xx = -xx;
    set(hObject,'String',num2str(xx))
end
W = str2double(get(handles.edit_FaultWidth,'String'));
dip = str2double(get(handles.edit_FaultDip,'String'));
depth = xx + W * cos((90-dip)*pi/180);
set(handles.edit_FaultDepth,'String',num2str(depth));
seg = get(handles.popup_segment,'Value');
handles.FaultTopDepth{fault}(seg) = xx;
handles.FaultDepth{fault}(seg) = depth;
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function popup_segment_Callback(hObject, eventdata, handles)
seg = get(hObject,'Value');
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end

% Fault parameters
set(handles.edit_FaultLength,'String',num2str(handles.FaultLength{fault}(seg)))
set(handles.edit_FaultStrike,'String',num2str(handles.FaultStrike{fault}(seg),'%.1f'))

if (isnan(handles.FaultWidth{fault}(seg)))     str = '';
else    str = num2str(handles.FaultWidth{fault}(seg));     end
set(handles.edit_FaultWidth,'String',str)

set(handles.edit_FaultDip,'String',num2str(handles.FaultDip{fault}(seg),'%.1f'))
set(handles.edit_FaultTopDepth,'String',num2str(handles.FaultTopDepth{fault}(seg)))

if (isnan(handles.FaultDepth{fault}(seg)))     str = '';
else    str = num2str(handles.FaultDepth{fault}(seg));     end
set(handles.edit_FaultDepth,'String',str)

% Dislocation parameters
set(handles.edit_DislocStrike,'String',num2str(handles.DislocStrike{fault}(seg),'%.1f'))
if (isnan(handles.DislocSlip{fault}(seg)))     str = '';
else    str = num2str(handles.DislocSlip{fault}(seg));     end
set(handles.edit_DislocSlip,'String',str)
if (isnan(handles.DislocRake{fault}(seg)))     str = '';
else    str = num2str(handles.DislocRake{fault}(seg),'%.1f');     end
set(handles.edit_DislocRake,'String',str)

% -----------------------------------------------------------------------------------------
function popup_fault_Callback(hObject, eventdata, handles)
fault = get(hObject,'Value');
S = [];
for (i=1:handles.nvert(fault))     S = [S; ['Segment ' num2str(i)]];   end
set(handles.popup_segment,'String',cellstr(S),'Value',1)    
seg = 1;    % Make current the first segment

% Identify the currently active fault by setting its linestyle to dash
set(handles.h_fault,'LineStyle','-')
set(handles.h_fault(fault),'LineStyle','--')

% Set the hide planes checkbox with the correct value for this fault
if (handles.hide_planes(fault))
    set(handles.checkbox_hideFaultPlanes,'Value',1)
else
    set(handles.checkbox_hideFaultPlanes,'Value',0)
end

% Fault parameters
set(handles.edit_FaultLength,'String',num2str(handles.FaultLength{fault}(seg)))
set(handles.edit_FaultStrike,'String',num2str(handles.FaultStrike{fault}(seg),'%.1f'))

if (isnan(handles.FaultWidth{fault}(seg)))     str = '';
else    str = num2str(handles.FaultWidth{fault}(seg));     end
set(handles.edit_FaultWidth,'String',str)

set(handles.edit_FaultDip,'String',num2str(handles.FaultDip{fault}(seg),'%.1f'))
set(handles.edit_FaultTopDepth,'String',num2str(handles.FaultTopDepth{fault}(seg)))

if (isnan(handles.FaultDepth{fault}(seg)))     str = '';
else    str = num2str(handles.FaultDepth{fault}(seg));     end
set(handles.edit_FaultDepth,'String',str)

% Dislocation parameters
set(handles.edit_DislocStrike,'String',num2str(handles.DislocStrike{fault}(seg),'%.1f'))
if (isnan(handles.DislocSlip{fault}(seg)))     str = '';
else    str = num2str(handles.DislocSlip{fault}(seg));     end
set(handles.edit_DislocSlip,'String',str)
if (isnan(handles.DislocRake{fault}(seg)))     str = '';
else    str = num2str(handles.DislocRake{fault}(seg),'%.1f');     end
set(handles.edit_DislocRake,'String',str)
if (handles.Mw(fault) > 0)
    txt = ['Moment Magnitude = ' num2str(handles.Mw(fault),'%.1f')];
    set(handles.h_txt_Mw,'String',txt,'Position',handles.txt_Mw_pos + [0 0 30 0])
else
    set(handles.h_txt_Mw,'String','Moment Magnitude = ','Position',handles.txt_Mw_pos)
end
refresh(handles.h_calling_fig);         % otherwise, ML BUG

% ------------------------------------------------------------------------------------
function edit_DislocStrike_Callback(hObject, eventdata, handles)
D2R = pi / 180;
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
xx = str2double(get(hObject,'String'));
f_strike = str2double(get(handles.edit_FaultStrike,'String'));      % Fault strike
slip = str2double(get(handles.edit_DislocSlip,'String'));           % Dislocation slip
seg = get(handles.popup_segment,'Value');
handles.DislocStrike{fault}(seg) = xx;
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_DislocRake_Callback(hObject, eventdata, handles)
xx = str2double(get(hObject,'String'));
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
seg = get(handles.popup_segment,'Value');
handles.DislocRake{fault}(seg) = xx;
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_DislocSlip_Callback(hObject, eventdata, handles)
xx = str2double(get(hObject,'String'));
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
seg = get(handles.popup_segment,'Value');
if (isnan(xx))
    set(hObject,'String','')
    handles.DislocSlip{fault}(seg) = NaN;
else
    handles.DislocSlip{fault}(seg) = xx;
end

% Compute Moment magnitude
M0 = 3e10 * handles.um_milhao * handles.DislocSlip{fault}(:) .* handles.FaultWidth{fault}(:) .* ...
    str2double(get(handles.edit_FaultLength,'String'));
if (length(M0) > 1)     M0 = sum(M0);   end
mag = 2/3*(log10(M0) - 9.1);
if (~isnan(mag))
    txt = ['Moment Magnitude = ' num2str(mag,'%.1f')];
    set(handles.h_txt_Mw,'String',txt,'Position',handles.txt_Mw_pos + [0 0 30 0])
    handles.Mw(fault) = mag;
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Xmin_Callback(hObject, eventdata, handles)
xx = get(hObject,'String');     val = test_dms(xx);
if ~isempty(val)            % when dd:mm or dd:mm:ss was given
    x_min = 0;
    if str2double(val{1}) > 0
        for i = 1:length(val)   x_min = x_min + str2double(val{i}) / (60^(i-1));    end
    else
        for i = 1:length(val)   x_min = x_min - abs(str2double(val{i})) / (60^(i-1));   end
    end
    handles.x_min = x_min;
    if ~isempty(handles.x_max) & x_min >= handles.x_max
        errordlg('West Longitude >= East Longitude ','Error in Longitude limits')
        set(hObject,'String','');   guidata(hObject, handles);  return
    end
    nc = get(handles.edit_Ncols,'String');
    if ~isempty(handles.x_max) & ~isempty(nc)       % x_max and ncols boxes are filled
        % Compute Ncols, but first must recompute x_inc
        x_inc = ivan_the_terrible((handles.x_max - x_min),round(abs(str2double(nc))),1);
        xx = floor((handles.x_max - str2double(xx)) / (str2double(get(handles.edit_Xinc,'String')))+0.5) + handles.one_or_zero;
        set(handles.edit_Xinc,'String',num2str(x_inc,10))
    elseif ~isempty(handles.x_max)      % x_max box is filled but ncol is not, so put to the default (100)
        x_inc = ivan_the_terrible((handles.x_max - x_min),100,1);
        set(handles.edit_Xinc,'String',num2str(x_inc,10))
        set(handles.edit_Ncols,'String','100')
    end
else                % box is empty, so clear also x_inc and ncols
    set(handles.edit_Xinc,'String','');     set(handles.edit_Ncols,'String','');
    set(hObject,'String','');
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Xmax_Callback(hObject, eventdata, handles)
xx = get(hObject,'String');     val = test_dms(xx);
if ~isempty(val)
    x_max = 0;
    if str2double(val{1}) > 0
        for i = 1:length(val)   x_max = x_max + str2double(val{i}) / (60^(i-1));    end
    else
        for i = 1:length(val)   x_max = x_max - abs(str2double(val{i})) / (60^(i-1));   end
    end
    handles.x_max = x_max;
    if ~isempty(handles.x_min) & x_max <= handles.x_min 
        errordlg('East Longitude <= West Longitude','Error in Longitude limits')
        set(hObject,'String','');   guidata(hObject, handles);  return
    end
    nc = get(handles.edit_Ncols,'String');
    if ~isempty(handles.x_min) & ~isempty(nc)       % x_max and ncols boxes are filled
        % Compute Ncols, but first must recompute x_inc
        x_inc = ivan_the_terrible((x_max - handles.x_min),round(abs(str2double(nc))),1);
        xx = floor((handles.x_min - str2double(xx)) / (str2double(get(handles.edit_Xinc,'String')))+0.5) + handles.one_or_zero;
        set(handles.edit_Xinc,'String',num2str(x_inc,10))
    elseif ~isempty(handles.x_min)      % x_min box is filled but ncol is not, so put to the default (100)
        x_inc = ivan_the_terrible((x_max - handles.x_min),100,1);
        set(handles.edit_Xinc,'String',num2str(x_inc,10))
        set(handles.edit_Ncols,'String','100')
    end
else                % box is empty, so clear also x_inc and ncols
    set(handles.edit_Xinc,'String','');     set(handles.edit_Ncols,'String','');
    set(hObject,'String','');
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Xinc_Callback(hObject, eventdata, handles)
dms = 0;
xx = get(hObject,'String');     val = test_dms(xx);
if isempty(val),    return;     end
% If it survived then ...
if length(val) > 1    dms = 1;      end         % inc given in dd:mm or dd:mm:ss format
x_inc = 0;
for i = 1:length(val)   x_inc = x_inc + str2double(val{i}) / (60^(i-1));    end
if ~isempty(handles.x_min) & ~isempty(handles.x_max)
    % Make whatever x_inc given compatible with GMT_grd_RI_verify
    x_inc = ivan_the_terrible((handles.x_max - handles.x_min), x_inc,2);
    if ~dms         % case of decimal unities
        set(hObject,'String',num2str(x_inc,8))
        ncol = floor((handles.x_max - handles.x_min) / x_inc + 0.5) + handles.one_or_zero;
    else            % inc was in dd:mm or dd:mm:ss format
        ncol = floor((handles.x_max - handles.x_min) / x_inc + 0.5) + handles.one_or_zero;
        ddmm = dec2deg(x_inc);
        set(hObject,'String',ddmm)
    end
    set(handles.edit_Ncols,'String',num2str(ncol))
end
handles.dms_xinc = dms;     handles.x_inc = str2double(xx);
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Ncols_Callback(hObject, eventdata, handles)
xx = get(hObject,'String');
if isempty(xx)          % Idiot user attempt. Reset ncols.
    set(hObject,'String',handles.ncols);    return;
end
if ~isempty(get(handles.edit_Xmin,'String')) & ~isempty(get(handles.edit_Xmax,'String')) & ...
        ~isempty(get(handles.edit_Xinc,'String')) & ~isempty(xx)
    x_inc = ivan_the_terrible((handles.x_max - handles.x_min),round(abs(str2double(xx))),1);
    if handles.dms_xinc        % x_inc was given in dd:mm:ss format
        ddmm = dec2deg(x_inc);
        set(handles.edit_Xinc,'String',ddmm)
    else                    % x_inc was given in decimal format
        set(handles.edit_Xinc,'String',num2str(x_inc,10));
    end
    handles.ncols = str2double(xx);
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Ymin_Callback(hObject, eventdata, handles)
% Read value either in decimal or in the dd:mm or dd_mm:ss formats and do some tests
xx = get(hObject,'String');     val = test_dms(xx);
if ~isempty(val)
    y_min = 0;
    if str2double(val{1}) > 0
        for i = 1:length(val)   y_min = y_min + str2double(val{i}) / (60^(i-1));    end
    else
        for i = 1:length(val)   y_min = y_min - abs(str2double(val{i})) / (60^(i-1));   end
    end
    handles.y_min = y_min;
    if ~isempty(handles.y_max) & y_min >= handles.y_max
        errordlg('South Latitude >= North Latitude','Error in Latitude limits')
        set(hObject,'String','');   guidata(hObject, handles);  return
    end
    nr = get(handles.edit_Nrows,'String');
    if ~isempty(handles.y_max) & ~isempty(nr)       % y_max and nrows boxes are filled
        % Compute Nrowss, but first must recompute y_inc
        y_inc = ivan_the_terrible((handles.y_max - y_min),round(abs(str2double(nr))),1);
        xx = floor((handles.y_max - str2double(xx)) / (str2double(get(handles.edit_Yinc,'String')))+0.5) + handles.one_or_zero;
        set(handles.edit_Yinc,'String',num2str(y_inc,10))
    elseif ~isempty(handles.y_max)      % y_max box is filled but nrows is not, so put to the default (100)
        y_inc = ivan_the_terrible((handles.y_max - y_min),100,1);
        set(handles.edit_Yinc,'String',num2str(y_inc,10))
        set(handles.edit_Nrows,'String','100')
    end
else                % box is empty, so clear also y_inc and nrows
    set(handles.edit_Yinc,'String','');     set(handles.edit_Nrows,'String','');
    set(hObject,'String','');
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Ymax_Callback(hObject, eventdata, handles)
% Read value either in decimal or in the dd:mm or dd_mm:ss formats and do some tests
xx = get(hObject,'String');     val = test_dms(xx);
if ~isempty(val)
    y_max = 0;
    if str2double(val{1}) > 0
        for i = 1:length(val)   y_max = y_max + str2double(val{i}) / (60^(i-1));    end
    else
        for i = 1:length(val)   y_max = y_max - abs(str2double(val{i})) / (60^(i-1));   end
    end
    handles.y_max = y_max;
    if ~isempty(handles.y_min) & y_max <= handles.y_min 
        errordlg('North Latitude <= South Latitude','Error in Latitude limits')
        set(hObject,'String','');   guidata(hObject, handles);  return
    end
    nr = get(handles.edit_Nrows,'String');
    if ~isempty(handles.y_min) & ~isempty(nr)       % y_min and nrows boxes are filled
        % Compute Nrows, but first must recompute y_inc
        y_inc = ivan_the_terrible((y_max - handles.y_min),round(abs(str2double(nr))),1);
        xx = floor((handles.y_min - str2double(xx)) / (str2double(get(handles.edit_Yinc,'String')))+0.5) + handles.one_or_zero;
        set(handles.edit_Yinc,'String',num2str(y_inc,10))
    elseif ~isempty(handles.y_min)      % y_min box is filled but nrows is not, so put to the default (100)
        y_inc = ivan_the_terrible((y_max - handles.y_min),100,1);
        set(handles.edit_Yinc,'String',num2str(y_inc,10))
        set(handles.edit_Nrows,'String','100')
    end
else                % This box is empty, so clear also y_inc and nrows
    set(handles.edit_Yinc,'String','');     set(handles.edit_Nrows,'String','');
    set(hObject,'String','');
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Yinc_Callback(hObject, eventdata, handles)
dms = 0;
xx = get(hObject,'String');     val = test_dms(xx);
if isempty(val)
    set(hObject, 'String', '');    return
end
% If it survived then ...
if length(val) > 1    dms = 1;      end         % inc given in dd:mm or dd:mm:ss format
y_inc = 0;
for i = 1:length(val)   y_inc = y_inc + str2double(val{i}) / (60^(i-1));    end
if ~isempty(handles.y_min) & ~isempty(handles.y_max)
    % Make whatever y_inc given compatible with GMT_grd_RI_verify
    y_inc = ivan_the_terrible((handles.y_max - handles.y_min), y_inc,2);
    if ~dms         % case of decimal unities
        set(hObject,'String',num2str(y_inc,10))
        nrow = floor((handles.y_max - handles.y_min) / y_inc + 0.5) + handles.one_or_zero;
    else            % inc was in dd:mm or dd:mm:ss format
        nrow = floor((handles.y_max - handles.y_min) / y_inc + 0.5) + handles.one_or_zero;
        ddmm = dec2deg(y_inc);
        set(hObject,'String',ddmm)
    end
    set(handles.edit_Nrows,'String',num2str(nrow))
end
handles.dms_yinc = dms;     handles.y_inc = str2double(xx);
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function edit_Nrows_Callback(hObject, eventdata, handles)
xx = get(hObject,'String');
if isempty(xx)          % Idiot user attempt. Reset nrows.
    set(hObject,'String',handles.nrows);    return;
end
if ~isempty(get(handles.edit_Ymin,'String')) & ~isempty(get(handles.edit_Ymax,'String')) & ...
        ~isempty(get(handles.edit_Yinc,'String'))
    y_inc = ivan_the_terrible((handles.y_max - handles.y_min),round(abs(str2double(xx))),1);
    if handles.dms_yinc        % y_inc was given in dd:mm:ss format
        ddmm = dec2deg(y_inc);
        set(handles.edit_Yinc,'String',ddmm)
    else                    % y_inc was given in decimal format
        set(handles.edit_Yinc,'String',num2str(y_inc,10));
    end
    handles.nrows = str2double(xx);
end
guidata(hObject, handles);

% ------------------------------------------------------------------------------------
function pushbutton_Help_R_Callback(hObject, eventdata, handles)
message = {'That''s prety obvious to guess what this option does. You select an area,'
    'the grid spacing or the number of rows/columns and the deformation will'
    'be computed at all nodes of that grid.'};
helpdlg(message,'Help on deformation grid');

% ------------------------------------------------------------------------------------
function pushbutton_compute_Callback(hObject, eventdata, handles)
% If cartesian coordinates, they must be in meters
if (any(isnan(cat(2,handles.FaultWidth{:}))))
    errordlg('One or more segments where not set with the fault''s Width','Error');    return
end
if (any(isnan(cat(2,handles.FaultDepth{:}))))
    errordlg('One or more segments where not set with the fault''s Depth','Error');    return
end
if (any(isnan(cat(2,handles.DislocRake{:}))))
    errordlg('One or more segments where not set with the movement''s rake','Error');    return
end
if (any(isnan(cat(2,handles.DislocSlip{:}))))
    errordlg('One or more segments where not set with the movement''s slip','Error');    return
end

% Get grid params
xmin = str2double(get(handles.edit_Xmin,'String'));
xmax = str2double(get(handles.edit_Xmax,'String'));
ymin = str2double(get(handles.edit_Ymin,'String'));
ymax = str2double(get(handles.edit_Ymax,'String'));
xinc = str2double(get(handles.edit_Xinc,'String'));
yinc = str2double(get(handles.edit_Yinc,'String'));
nrow = str2double(get(handles.edit_Nrows,'String'));
ncol = str2double(get(handles.edit_Ncols,'String'));

if (handles.is_km)      % Than we must convert those to meters
    xmin = xmin * 1e3;    xmax = xmax * 1e3;
    ymin = ymin * 1e3;    ymax = ymax * 1e3;
    xinc = xinc * 1e3;    yinc = yinc * 1e3;
end

opt_R = ['-R' num2str(xmin,'%.8f') '/' num2str(xmax,'%.8f') ...
        '/' num2str(ymin,'%.8f') '/' num2str(ymax,'%.8f')];
opt_I = ['-I' num2str(xinc,'%.8f') '/' num2str(yinc,'%.8f')];

n_seg = sum(handles.nvert);
x = handles.fault_x;            y = handles.fault_y;
if (~iscell(x))                 x = {x};    y = {y};    end
kk = 1;
for (i=1:handles.n_faults)
	for (k=1:handles.nvert(i))
        if (handles.is_meters)      % Fault's length must be given in km to mansinha_m
            handles.FaultLength{i}(k) = handles.FaultLength{i}(k) / 1000;
        elseif (handles.is_km)      % This is a messy case. -E & -I must also be in meters
            x{i}(k) = x{i}(k) * 1e3;    y{i}(k) = y{i}(k) * 1e3;
        end
        opt_F{kk} = ['-F' num2str(handles.FaultLength{i}(k)) '/' num2str(handles.FaultWidth{i}(k)) '/' ...
                num2str(handles.FaultTopDepth{i}(k))];
        opt_A{kk} = ['-A' num2str(handles.FaultDip{i}(k)) '/' num2str(handles.FaultStrike{i}(k)) '/' ...
                num2str(handles.DislocRake{i}(k)) '/' num2str(handles.DislocSlip{i}(k))];
        opt_E{kk} = ['-E' num2str(x{i}(k),'%.5f') '/' num2str(y{i}(k),'%.5f')];
        kk = kk + 1;
	end
end

if (handles.geog)   opt_M = '-M';
else                opt_M = '';     end

% Compute deformation
if (n_seg > 1)
    U = zeros(nrow,ncol);
    h = waitbar(0,'Computing deformation');
	for k=1:n_seg
        waitbar(k/n_seg)
        U0 = double(mansinha_m(opt_R, opt_I, opt_A{k}, opt_F{k}, opt_E{k}, opt_M));
        U = U0 + U;
	end
    close(h);    clear U0;
else
    U = double(mansinha_m(opt_R, opt_I, opt_A{1}, opt_F{1}, opt_E{1}, opt_M));
end

z_max = max(U(:));     z_min = min(U(:));
U = single(U);
dx = str2double(get(handles.edit_Xinc,'String'));
dy = str2double(get(handles.edit_Yinc,'String'));

tmp = [xmin xmax ymin ymax z_min z_max 0];
head.head = [tmp dx dy];
head.X = linspace(xmin,xmax,ncol);
tmp = linspace(ymin,ymax,nrow);
head.Y = tmp';

new_window = mirone(U,head,'Deformation',handles.h_calling_fig);

% ------------------------------------------------------------------------------------
function pushbutton_cancel_Callback(hObject, eventdata, handles)
delete(handles.figure1)

% -----------------------------------------------------------------------------------------
function len = LineLength(h,geog)
x = get(h,'XData');     y = get(h,'YData');
len = [];
if (~iscell(x))
	if (geog)
        D2R = pi/180;    earth_rad = 6371;
        x = x * D2R;    y = y * D2R;
        lat_i = y(1:length(y)-1);   lat_f = y(2:length(y));     clear y;
        lon_i = x(1:length(x)-1);   lon_f = x(2:length(x));     clear x;
        tmp = sin(lat_i).*sin(lat_f) + cos(lat_i).*cos(lat_f).*cos(lon_f-lon_i);
        clear lat_i lat_f lon_i lon_f;
        len = [len; acos(tmp) * earth_rad];         % Distance in km
	else
        dx = diff(x);   dy = diff(y);
        len = [len; sqrt(dx.*dx + dy.*dy)];         % Distance in user unites
	end
else
	if (geog)
        D2R = pi/180;    earth_rad = 6371;
        for (k=1:length(x))
            xx = x{k} * D2R;    yy = y{k} * D2R;
            lat_i = yy(1:length(yy)-1);   lat_f = yy(2:length(yy));
            lon_i = xx(1:length(xx)-1);   lon_f = xx(2:length(xx));
            tmp = sin(lat_i).*sin(lat_f) + cos(lat_i).*cos(lat_f).*cos(lon_f-lon_i);
            len{k} = acos(tmp) * earth_rad;         % Distance in km
        end
	else
        for (k=1:length(x))
            xx = x{k};      yy = y{k};
            dx = diff(xx);  dy = diff(yy);
            len{k} = sqrt(dx.*dx + dy.*dy);         % Distance in user unites
        end
	end
end

% -----------------------------------------------------------------------------------------
function popup_GridCoords_Callback(hObject, eventdata, handles)
xx = get(hObject,'Value');
if (xx == 1)        handles.geog = 1;       handles.is_meters = 0;  handles.is_km = 0;  handles.um_milhao = 1e6;
elseif (xx == 2)    handles.is_meters = 1;  handles.is_geog = 0;    handles.is_km = 0;  handles.um_milhao = 1e3;
elseif (xx == 3)    handles.is_km = 1;      handles.is_geog = 0;    handles.is_meters = 0;  handles.um_milhao = 1e6;
end
guidata(hObject,handles)

% -----------------------------------------------------------------------------------------
function checkbox_hideFaultPlanes_Callback(hObject, eventdata, handles)
if (handles.n_faults > 1)   fault = get(handles.popup_fault,'Value');
else                        fault = 1;      end
hp = getappdata(handles.h_fault(fault),'PatchHand');
if (get(hObject,'Value'))
    try,    set(hp,'Visible','off');    end
    handles.hide_planes(fault) = 1;
else
    try,    set(hp,'Visible','on');     end
    handles.hide_planes(fault) = 0;
end
guidata(hObject,handles)

% --- Creates and returns a handle to the GUI figure. 
function deform_mansinha_LayoutFcn(h1,handles);

set(h1, 'PaperUnits',get(0,'defaultfigurePaperUnits'),...
'Color',get(0,'factoryUicontrolBackgroundColor'),...
'MenuBar','none',...
'Name','deform_mansinha',...
'NumberTitle','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[520 529 540 271],...
'Renderer',get(0,'defaultfigureRenderer'),...
'RendererMode','manual',...
'Resize','off',...
'Tag','figure1',...
'HandleVisibility','callback',...
'UserData',[]);

h2 = uicontrol('Parent',h1,'Position',[10 126 181 131],'String',{''},...
'Style','frame','Tag','frame1');

h3 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_FaultLength_Callback'},...
'Position',[20 213 71 21],...
'Style','edit',...
'TooltipString','Fault length (km)',...
'Tag','edit_FaultLength');

h4 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_FaultWidth_Callback'},...
'Position',[110 213 71 21],...
'Style','edit',...
'TooltipString','Fault width (km)',...
'Tag','edit_FaultWidth');

h5 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_FaultStrike_Callback'},...
'Position',[20 173 71 21],...
'Style','edit',...
'TooltipString','Fault strike (degrees)',...
'Tag','edit_FaultStrike');

h6 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_FaultDip_Callback'},...
'Position',[110 173 71 21],...
'Style','edit',...
'TooltipString','Fault dip (degrees)',...
'Tag','edit_FaultDip');

h7 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_FaultDepth_Callback'},...
'Position',[20 134 71 21],...
'Style','edit',...
'TooltipString','Depth of the base of fault''s plane',...
'Tag','edit_FaultDepth');

h8 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_FaultTopDepth_Callback'},...
'Position',[110 133 71 21],...
'Style','edit',...
'TooltipString','Alternatively, give depth to the fault''s top ',...
'Tag','edit_FaultTopDepth');

h9 = uicontrol('Parent',h1,'Enable','inactive','Position',[36 235 41 13],...
'String','Length','Style','text','Tag','text1');

h10 = uicontrol('Parent',h1,'Enable','inactive','Position',[125 236 41 13],...
'String','Width','Style','text','Tag','text2');

h11 = uicontrol('Parent',h1,'Enable','inactive','Position',[34 195 41 13],...
'String','Strike','Style','text','Tag','text3');

h12 = uicontrol('Parent',h1,'Enable','inactive','Position',[124 195 41 13],...
'String','Dip','Style','text','Tag','text4');

h13 = uicontrol('Parent',h1,'Enable','inactive','Position',[108 154 75 16],...
'String','Depth to Top','Style','text',...
'TooltipString','Depth to the top of the fault (>= 0)','Tag','text5');

h14 = uicontrol('Parent',h1,'Enable','inactive','Position',[34 155 41 16],...
'String','Depth','Style','text',...
'TooltipString','Depth to the top of the fault (>= 0)','Tag','text6');

h15 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'popup_segment_Callback'},...
'Position',[210 216 91 22],...
'Style','popupmenu',...
'TooltipString','Set parameters with respect to this segment',...
'Value',1,...
'Tag','popup_segment');

h16 = uicontrol('Parent',h1,'Enable','inactive','Position',[229 238 48 16],...
'String','Segments','Style','text','Tag','fault_segment');

h17 = uicontrol('Parent',h1,'Enable','inactive','Position',[53 250 85 15],...
'String','Fault Geometry','Style','text','Tag','text8');

h18 = uicontrol('Parent',h1,'Position',[320 126 211 131],...
'String',{''},'Style','frame','Tag','frame2');

h19 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_DislocStrike_Callback'},...
'Position',[330 213 51 21],...
'Style','edit',...
'Tag','edit_DislocStrike');

h20 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_DislocRake_Callback'},...
'Position',[400 213 51 21],...
'Style','edit',...
'TooltipString','Displacement angle clock-wise from horizontal',...
'Tag','edit_DislocRake');

h21 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_DislocSlip_Callback'},...
'Position',[470 213 51 21],...
'Style','edit',...
'TooltipString','Total displacement',...
'Tag','edit_DislocSlip');

h22 = uicontrol('Parent',h1,'Enable','inactive','Position',[335 235 41 13],...
'String','Strike','Style','text','Tag','text9');

h23 = uicontrol('Parent',h1,'Enable','inactive','Position',[404 235 41 13],...
'String','Rake','Style','text','Tag','text10');

h24 = uicontrol('Parent',h1,'Enable','inactive','Position',[474 235 41 13],...
'String','Slip','Style','text','Tag','text11');

h25 = uicontrol('Parent',h1,'Enable','inactive','Position',[373 250 111 15],...
'String','Dislocation Geometry','Style','text','Tag','text12');

h26 = uicontrol('Parent',h1,'Enable','inactive','Position',[10 11 350 93],...
'String',{''},'Style','frame','Tag','frame3');

h27 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Xmin_Callback'},...
'HorizontalAlignment','left',...
'Position',[76 64 71 21],...
'Style','edit',...
'TooltipString','X min value',...
'Tag','edit_Xmin');

h28 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Xmax_Callback'},...
'HorizontalAlignment','left',...
'Position',[152 64 71 21],...
'Style','edit',...
'TooltipString','X max value',...
'Tag','edit_Xmax');

h29 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Xinc_Callback'},...
'HorizontalAlignment','left',...
'Position',[228 64 71 21],...
'Style','edit',...
'TooltipString','DX grid spacing',...
'Tag','edit_Xinc');

h30 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Ncols_Callback'},...
'Position',[304 64 45 21],...
'Style','edit',...
'TooltipString','Number of columns in the grid',...
'Tag','edit_Ncols');

h31 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Ymin_Callback'},...
'HorizontalAlignment','left',...
'Position',[76 38 71 21],...
'Style','edit',...
'TooltipString','Y min value',...
'Tag','edit_Ymin');

h32 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Ymax_Callback'},...
'HorizontalAlignment','left',...
'Position',[152 38 71 21],...
'Style','edit',...
'TooltipString','Y max value',...
'Tag','edit_Ymax');

h33 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Yinc_Callback'},...
'HorizontalAlignment','left',...
'Position',[228 38 71 21],...
'Style','edit',...
'TooltipString','DY grid spacing',...
'Tag','edit_Yinc');

h34 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'edit_Nrows_Callback'},...
'Position',[304 38 45 21],...
'Style','edit',...
'TooltipString','Number of columns in the grid',...
'Tag','edit_Nrows');

h35 = uicontrol('Parent',h1,...
'BackgroundColor',[0.831372559070587 0.815686285495758 0.7843137383461],...
'Callback',{@deform_mansinha_uicallback,h1,'pushbutton_Help_R_Callback'},...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'Position',[289 16 61 18],...
'String','?',...
'Tag','pushbutton_Help_R');

h36 = uicontrol('Parent',h1,'Enable','inactive','Position',[18 69 55 15],...
'String','X Direction','Style','text','Tag','text13');

h37 = uicontrol('Parent',h1,'Enable','inactive','Position',[17 43 55 15],...
'String','Y Direction','Style','text','Tag','text14');

h38 = uicontrol('Parent',h1,'Enable','inactive','Position',[169 86 41 13],...
'String','Max','Style','text','Tag','text15');

h39 = uicontrol('Parent',h1,'Enable','inactive','Position',[91 87 41 13],...
'String','Min','Style','text','Tag','text16');

h40 = uicontrol('Parent',h1,'Enable','inactive','Position',[246 87 41 13],...
'String','Spacing','Style','text','Tag','text17');

h41 = uicontrol('Parent',h1,'Enable','inactive','Position',[302 87 51 13],...
'String','# of lines','Style','text','Tag','text18','UserData',[]);

h42 = uicontrol('Parent',h1,'Enable','inactive','Position',[30 97 121 15],...
'String','Griding Line Geometry','Style','text','Tag','text19');

h43 = uicontrol('Parent',h1,...
'Callback',{@deform_mansinha_uicallback,h1,'pushbutton_compute_Callback'},...
'FontWeight','bold',...
'Position',[430 43 71 23],...
'String','Compute',...
'Tag','pushbutton_compute');

h44 = uicontrol('Parent',h1,...
'Callback',{@deform_mansinha_uicallback,h1,'pushbutton_cancel_Callback'},...
'FontWeight','bold',...
'Position',[430 12 71 23],...
'String','Cancel',...
'Tag','pushbutton_cancel');

h45 = uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'popup_fault_Callback'},...
'Position',[209 171 91 22],'Style','popupmenu',...
'TooltipString','Toggle between the different faults',...
'Value',1,'Tag','popup_fault');

h46 = uicontrol('Parent',h1,...
'Enable','inactive','Position',[229 194 42 15],...
'String','Faults','Style','text','Tag','fault_number');

h47 = uicontrol('Parent',h1,...
'Callback',{@deform_mansinha_uicallback,h1,'checkbox_hideFaultPlanes_Callback'},...
'Position',[330 166 98 15],'String','Hide fault planes',...
'Style','checkbox','Tag','checkbox_hideFaultPlanes');

h48 = uicontrol('Parent',h1,'Enable','inactive','FontSize',10,...
'HorizontalAlignment','left','Position',[330 135 123 16],...
'String','Moment Magnitude =','Style','text','Tag','text_Mw');

uicontrol('Parent',h1,'Position',[224 150 50 15],'ForegroundColor',[1 0 0],...
'String','CONFIRM','Style','text','Tag','text22');

uicontrol('Parent',h1,'BackgroundColor',[1 1 1],...
'Callback',{@deform_mansinha_uicallback,h1,'popup_GridCoords_Callback'},...
'String', {'Geogs' 'Meters' 'Kilometers'},...
'Position',[209 127 91 22],'Style','popupmenu',...
'TooltipString','GRID COORDINATES: IT IS YOUR RESPONSABILITY THAT THIS IS CORRECT',...
'Value',1,'Tag','popup_GridCoords');

function deform_mansinha_uicallback(hObject, eventdata, h1, callback_name)
% This function is executed by the callback and than the handles is allways updated.
feval(callback_name,hObject,[],guidata(h1));
