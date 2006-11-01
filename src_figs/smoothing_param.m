function varargout = smoothing_param(varargin)
% M-File changed by desGUIDE 

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
smoothing_param_LayoutFcn(hObject,handles);
handles = guihandles(hObject);
 
% Reposition the window on screen
movegui(hObject,'northeast')

set(handles.edit_SmoothParam,'String',num2str(varargin{1}))
set(handles.edit_Xstart,'String',num2str(varargin{2}(1)))
set(handles.edit_Xstep,'String',num2str(varargin{2}(2)))
set(handles.edit_Xend,'String',num2str(varargin{2}(3)))

handles.smooth = varargin{1};           handles.smooth_orig = varargin{1};
handles.Xstart = varargin{2}(1);        handles.Xstart_orig = varargin{2}(1);
handles.Xstep = varargin{2}(2);         handles.Xstep_orig = varargin{2}(2);
handles.Xend = varargin{2}(3);          handles.Xend_orig = varargin{2}(3);
handles.h_parent_Fig = varargin{3};     handles.h_parent_Axes = varargin{4};
handles.hFig = hObject;

handles.h_dot = findobj(get(handles.h_parent_Axes,'Children'),'LineStyle','none');    % doted line has original data
handles.h_lin = findobj(get(handles.h_parent_Axes,'Children'),'LineStyle','-');       % this is the one to be replaced

% Choose default command line output for smoothing_param_export
handles.output = hObject;
guidata(hObject, handles);

% UIWAIT makes smoothing_param_export wait for user response (see UIRESUME)
% uiwait(handles.figure1);

set(hObject,'Visible','on');
% NOTE: If you make uiwait active you have also to uncomment the next three lines
% handles = guidata(hObject);
% out = smoothing_param_OutputFcn(hObject, [], handles);
% varargout{1} = out;

% --- Outputs from this function are returned to the command line.
function varargout = smoothing_param_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% Get default command line output from handles structure
varargout{1} = handles.output;

% ----------------------------------------------------------------------------
function edit_SmoothParam_Callback(hObject, eventdata, handles)
xx = get(hObject,'String');
handles.smooth = str2double(xx);
guidata(hObject, handles);

% ----------------------------------------------------------------------------
function edit_Xstart_Callback(hObject, eventdata, handles)
handles.Xstart = str2double(get(hObject,'String'));
if (handles.Xstart < handles.Xstart_orig)           % x lower than original x_min is not allowed
    handles.Xstart = handles.Xstart_orig;    set(hObject,'String',num2str(handles.Xstart_orig))
end
guidata(hObject, handles);

% ----------------------------------------------------------------------------
function edit_Xstep_Callback(hObject, eventdata, handles)
handles.Xstep = str2double(get(hObject,'String'));
guidata(hObject, handles);

% ----------------------------------------------------------------------------
function edit_Xend_Callback(hObject, eventdata, handles)
handles.Xend = str2double(get(hObject,'String'));
if (handles.Xend > handles.Xend_orig)           % x higher than original x_max is not allowed
    handles.Xend = handles.Xend_orig;    set(hObject,'String',num2str(handles.Xend_orig))
end
guidata(hObject, handles);

% ----------------------------------------------------------------------------
function pushbutton_Apply_Callback(hObject, eventdata, handles)
xx = get(handles.h_dot,'XData');    yy = get(handles.h_dot,'YData');
new_x = handles.Xstart:handles.Xstep:handles.Xend;
y = spl_fun('csaps',xx,yy,handles.smooth,new_x);
set(handles.h_lin,'XData',new_x,'YData',y);

% ----------------------------------------------------------------------------
function pushbutton_ResetOrigin_Callback(hObject, eventdata, handles)
set(handles.edit_SmoothParam,'String',num2str(handles.smooth_orig))
set(handles.edit_Xstart,'String',num2str(handles.Xstart_orig))
set(handles.edit_Xstep,'String',num2str(handles.Xstep_orig))
set(handles.edit_Xend,'String',num2str(handles.Xend_orig))
handles.smooth = handles.smooth_orig;       handles.Xstart = handles.Xstart_orig;
handles.Xstep = handles.Xstep_orig;         handles.Xend = handles.Xend_orig;
guidata(hObject, handles);

% ----------------------------------------------------------------------------
function pushbutton_Cancel_Callback(hObject, eventdata, handles)
delete(handles.h_dot)
delete(handles.hFig)

% ----------------------------------------------------------------------------
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
handles = guidata(hObject);    delete(handles.h_dot)
delete(hObject);

% ----------------------------------------------------------------------------
% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
handles = guidata(hObject);    delete(handles.h_dot)
delete(hObject);

% ----------------------------------------------------------------------------
% --- Creates and returns a handle to the GUI figure. 
function smoothing_param_LayoutFcn(h1,handles);

set(h1,...
'PaperUnits',get(0,'defaultfigurePaperUnits'),...
'CloseRequestFcn',{@figure1_CloseRequestFcn,handles},...
'Color',get(0,'factoryUicontrolBackgroundColor'),...
'KeyPressFcn',{@figure1_KeyPressFcn,handles},...
'MenuBar','none',...
'Name','Smoothing Params',...
'NumberTitle','off',...
'Position',[520 722 329 78],...
'RendererMode','manual',...
'Resize','off',...
'Tag','figure1',...
'UserData',[]);

h2 = uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Callback',{@smoothing_param_uicallback,h1,'edit_SmoothParam_Callback'},...
'HorizontalAlignment','left',...
'Position',[10 39 121 21],...
'Style','edit',...
'TooltipString','Enter a Smoothing Parameter between [0 1]',...
'Tag','edit_SmoothParam');

h3 = uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Callback',{@smoothing_param_uicallback,h1,'edit_Xstart_Callback'},...
'Position',[150 39 51 21],...
'Style','edit',...
'TooltipString','Fitting will start at this x min',...
'Tag','edit_Xstart');

h4 = uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Callback',{@smoothing_param_uicallback,h1,'edit_Xstep_Callback'},...
'Position',[210 39 51 21],...
'Style','edit',...
'TooltipString','x step for linear interpolation between x_min and x_max',...
'Tag','edit_Xstep');

h5 = uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Callback',{@smoothing_param_uicallback,h1,'edit_Xend_Callback'},...
'CData',[],...
'Position',[270 39 51 21],...
'Style','edit',...
'TooltipString','Fitting will stop at this x max',...
'Tag','edit_Xend');

h6 = uicontrol('Parent',h1,...
'Position',[151 60 51 15],...
'String','X-start',...
'Style','text',...
'Tag','text1');

h7 = uicontrol('Parent',h1,...
'Position',[210 60 51 15],...
'String','X-step',...
'Style','text',...
'Tag','text2');

h8 = uicontrol('Parent',h1,...
'Position',[270 60 51 15],...
'String','X-end',...
'Style','text',...
'Tag','text3');

h9 = uicontrol('Parent',h1,...
'Position',[11 60 119 15],...
'String','Smoothing parameter (p)',...
'Style','text',...
'Tag','text4');

h10 = uicontrol('Parent',h1,...
'Callback',{@smoothing_param_uicallback,h1,'pushbutton_Apply_Callback'},...
'Position',[185 8 66 23],...
'String','Apply',...
'Tag','pushbutton_Apply');

h11 = uicontrol('Parent',h1,...
'Callback',{@smoothing_param_uicallback,h1,'pushbutton_Cancel_Callback'},...
'Position',[256 8 66 23],...
'String','End',...
'Tag','pushbutton_Cancel');

h12 = uicontrol('Parent',h1,...
'Callback',{@smoothing_param_uicallback,h1,'pushbutton_ResetOrigin_Callback'},...
'Position',[10 8 108 23],...
'String','Reset original values',...
'TooltipString','Reset  p, X-start, X-step, X-end to their original values',...
'Tag','pushbutton_ResetOrigin');

function smoothing_param_uicallback(hObject, eventdata, h1, callback_name)
% This function is executed by the callback and than the handles is allways updated.
feval(callback_name,hObject,[],guidata(h1));
