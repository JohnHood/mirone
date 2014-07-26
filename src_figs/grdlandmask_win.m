function varargout = grdlandmask_win(varargin)
% Front end to grdlandmask MEX

%	Copyright (c) 2004-2014 by J. Luis
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

% $Id$

	hObject = figure('Vis','off');
	grdlandmask_win_LayoutFcn(hObject);
	handles = guihandles(hObject);
	move2side(hObject,'center')

	% Default size
	handles.nr_or = 361;	handles.nc_or = 721;
	head = [-180 180 -90 90 0 0 0 0.5 0.5];

	if ~isempty(varargin)
		handMir  = varargin{1};
		home_dir = handMir.home_dir;
		handles.IamCompiled = handMir.IamCompiled;
		if (~handMir.no_file && handMir.geog)			% If geogs, propose a mask that falls within data region
			head = handMir.head;
			handles.nr_or = round(diff(head(1:2)) / head(8)) + ~head(7);
			handles.nc_or = round(diff(head(3:4)) / head(9)) + ~head(7);
		end
	else
		handles.IamCompiled = false;
		home_dir = cd;
	end
	
	%-----------
	% See what we have regarding coastlines installation
	info = getappdata(0,'gmt_version'); 
	if (isempty(info))
        info = set_gmt(['GMT_USERDIR=' home_dir filesep 'gmt_userdir']);
        setappdata(0,'gmt_version',info);   % Save it so that the next time a new mirone window is opened
	end
	costas = false(1,5);
    if (info.full ~= 'y'),		costas(5) = true;    end
    if (info.high ~= 'y'),		costas(4) = true;    end
    if (info.intermediate ~= 'y'),		costas(3) = true;    end
    if (info.low ~= 'y'),		costas(2) = true;    end
    if (info.crude ~= 'y'),		costas(1) = true;    end
	costas_str = {'crude' 'low' 'intermediate' 'high' 'full'};
	costas_str(costas) = [];
	if (isempty(costas_str))
		errordlg('No Coastline database was found in this machine. No point to continue','Error')
		delete(hObject),	return
	else
		set(handles.popup_resolution, 'String', costas_str)
		val = 2;
		if (numel(costas_str) == 1),	val = 1;	end
		set(handles.popup_resolution, 'Val', val)
		handles.optD = ['-D' costas_str{val}(1)];
	end
	%----------------

	handles.x_min = [];             handles.x_max = [];
	handles.y_min = [];             handles.y_max = [];
	handles.opt_N = {'0' '1' '0' '1' '0'};
	handles.minLevel = 0;			handles.maxLevel = 4;
	handles.minArea = 0;

	%-----------
	% Fill in the grid limits boxes with calling fig values and save some limiting value
	set(handles.edit_x_min,'String',sprintf('%.8g',head(1)))
	set(handles.edit_x_max,'String',sprintf('%.8g',head(2)))
	set(handles.edit_y_min,'String',sprintf('%.8g',head(3)))
	set(handles.edit_y_max,'String',sprintf('%.8g',head(4)))
	handles.x_min = head(1);            handles.x_max = head(2);
	handles.y_min = head(3);            handles.y_max = head(4);
	handles.x_min_or = head(1);         handles.x_max_or = head(2);
	handles.y_min_or = head(3);         handles.y_max_or = head(4);
	handles.one_or_zero = ~head(7);

	% Fill in the x,y_inc and nrow,ncol boxes
	set(handles.edit_Nrows,'String',sprintf('%d',handles.nr_or))
	set(handles.edit_Ncols,'String',sprintf('%d',handles.nc_or))
	set(handles.edit_y_inc,'String',sprintf('%.12g',head(9)))
	set(handles.edit_x_inc,'String',sprintf('%.12g',head(8)))
	handles.dms_xinc = 0;    handles.dms_yinc = 0;
	handles.head = head;
	%----------------
	
	%------------ Give a Pro look (3D) to the frame boxes  -------------------------------
	h_t = [handles.text_GLG handles.text_Cr handles.text_Ma handles.text_nodes];
	new_frame3D(hObject, h_t, [handles.frame1 handles.frame2 handles.frame3 handles.frame4])
	%------------- END Pro look (3D) -----------------------------------------------------

	guidata(hObject, handles);
	set(hObject,'Visible','on');
	if (nargout),   varargout{1} = hObject;     end

% --------------------------------------------------------------------
function edit_x_min_CB(hObject, handles)
	dim_funs('xMin', hObject, handles)

% --------------------------------------------------------------------
function edit_x_max_CB(hObject, handles)
	dim_funs('xMax', hObject, handles)

% --------------------------------------------------------------------
function edit_y_min_CB(hObject, handles)
	dim_funs('yMin', hObject, handles)

% --------------------------------------------------------------------
function edit_y_max_CB(hObject, handles)
	dim_funs('yMax', hObject, handles)

% --------------------------------------------------------------------
function edit_x_inc_CB(hObject, handles)
	dim_funs('xInc', hObject, handles)

% --------------------------------------------------------------------
function edit_Ncols_CB(hObject, handles)
	dim_funs('nCols', hObject, handles)

% --------------------------------------------------------------------
function edit_y_inc_CB(hObject, handles)
	dim_funs('yInc', hObject, handles)

% --------------------------------------------------------------------
function edit_Nrows_CB(hObject, handles)
	dim_funs('nRows', hObject, handles)

% --------------------------------------------------------------------
function push_Help_R_F_T_CB(hObject, handles)
message = {'Min and Max, of "X Direction" and "Y Direction" specify the Region of'
    'interest. To specify boundaries in degrees and minutes [and seconds],'
    'use the dd:mm[:ss.xx] format.'
    '"Spacing" sets the grid size for grid output. You may choose different'
    'spacings for X and Y. Also here you can use the dd:mm[:ss.xx] format.'
    'In "#of lines" it is offered the easyeast way of controling the grid'
    'dimensions (lines & columns).'};
helpdlg(message,'Help on Grid Line Geometry');

% -----------------------------------------------------------------------------------
function popup_resolution_CB(hObject, handles)
	val = get(hObject,'Value');
	str = get(hObject,'String');
	str = str{val};
	switch str(1);
		case 'c',		handles.optD = '-Dc';
		case 'l',		handles.optD = '-Dl';
		case 'i',		handles.optD = '-Di';
		case 'h',		handles.optD = '-Dh';
		case 'f',		handles.optD = '-Df';
	end
	guidata(handles.figure1, handles);

% -----------------------------------------------------------------------------------
function push_helpOptionD_CB(hObject, handles)
	message = {'Selects the resolution of the data set to use: full, high,'
		'intermediate, low, and crude.  The  resolution drops off'
		'by 80% between data sets.'};
	helpdlg(message,'Help on Coast lines resolution');

% -----------------------------------------------------------------------------------
function edit_opt_A_CB(hObject, handles)
	xx = str2double(get(hObject,'String'));
	if (isnan(xx) || xx < 0)
		errordlg('Not a valid number','Error')
		set(hObject,'String','')
		handles.minArea = 0;
	else
		handles.minArea = str2double(xx);
	end
	guidata(handles.figure1, handles);

% -----------------------------------------------------------------------------------
function popup_opt_A_minLevel_CB(hObject, handles)
	handles.minLevel = get(hObject,'Val') - 1;
	guidata(handles.figure1, handles);

% -----------------------------------------------------------------------------------
function popup_opt_A_maxLevel_CB(hObject, handles)
	handles.maxLevel = get(hObject,'Val') - 1;
	if (handles.maxLevel <= handles.minLevel)
		set(hObject,'Val',handles.maxLevel + 1)
		return
	end
	guidata(handles.figure1, handles);

% -----------------------------------------------------------------------------------
function push_helpOptionA_CB(hObject, handles)
	message = {'Features with an area smaller than "Min Area" in km^2 or of hierarchical'
		'level that is lower than min_level or higher than max_level will not be'
		'plotted [Default is 0/0/4 (all features)]. See DATABASE INFORMATION'
		'in pscoast man page for more details.'};
	helpdlg(message,'Help on Min Area');

% -----------------------------------------------------------------------------------
function edit_ocean_CB(hObject, handles)
	xx = get(hObject,'String');
	if (isnan(str2double(xx))),		set(hObject,'String','NaN'),	xx = 'NaN';	end
	handles.opt_N{1} = xx;
	guidata(handles.figure1, handles)

% -----------------------------------------------------------------------------------
function edit_land_CB(hObject, handles)
	xx = get(hObject,'String');
	if (isnan(str2double(xx))),		set(hObject,'String','NaN'),	xx = 'NaN';	end
	handles.opt_N{2} = xx;
	guidata(handles.figure1, handles)

% -----------------------------------------------------------------------------------
function edit_lake_CB(hObject, handles)
	xx = get(hObject,'String');
	if (isnan(str2double(xx))),		set(hObject,'String','NaN'),	xx = 'NaN';	end
	handles.opt_N{3} = xx;
	guidata(handles.figure1, handles)

% -----------------------------------------------------------------------------------
function edit_island_CB(hObject, handles)
	xx = get(hObject,'String');
	if (isnan(str2double(xx))),		set(hObject,'String','NaN'),	xx = 'NaN';	end
	handles.opt_N{4} = xx;
	guidata(handles.figure1, handles)

% -----------------------------------------------------------------------------------
function edit_pond_CB(hObject, handles)
	xx = get(hObject,'String');
	if (isnan(str2double(xx))),		set(hObject,'String','NaN'),	xx = 'NaN';	end
	handles.opt_N{5} = xx;
	guidata(handles.figure1, handles)

% --------------------------------------------------------------------
function push_OK_CB(hObject, handles)

	opt_N = ' ';	opt_A = ' ';	opt_D = ' ';	opt_F = ' ';	opt_V = ' ';
	if isempty(handles.x_min) || isempty(handles.x_max) || isempty(handles.y_min) || isempty(handles.y_max)
		errordlg('One or more grid limits are empty. Open your yes.','Error');    return
	end

	nodes = str2double(handles.opt_N);
	if (~isequal(nodes, [0 1 0 1 0]))		% Non default, so we must transmit the whole -N option
		opt_N = ['-N' handles.opt_N{1} '/' handles.opt_N{2} '/' handles.opt_N{3} '/' handles.opt_N{4} '/' handles.opt_N{5}];
	end

	if (get(handles.check_bdNodes,'Value'))		% Non default, so we must transmit the whole -N option
		if (opt_N(1) == ' ')
			opt_N = ['-N' handles.opt_N{1} '/' handles.opt_N{2} '/' handles.opt_N{3} '/' handles.opt_N{4} '/' handles.opt_N{5} 'o'];
		else
			opt_N = [opt_N 'o'];
		end
	end

	if (get(handles.check_verbose,'Value')),	opt_V = '-V';	end
	if (~get(handles.check_gridReg,'Value')),	opt_F = '-F';	end
	if (handles.optD(3) ~= 'l'),				opt_D = handles.optD;	end

	opt_R = sprintf('-R%.10g/%.10g/%.10g/%.10g',handles.x_min, handles.x_max, handles.y_min, handles.y_max);
	opt_I = sprintf('-I%s/%s',get(handles.edit_x_inc,'String'), get(handles.edit_y_inc,'String'));

	if (handles.minArea > 0)
		opt_A = sprintf('-A%.1f',handles.minArea);
	end
	if (handles.minLevel > 0)
		opt_A = sprintf('-A%.1f/%d/%d',handles.minArea, handles.minLevel, handles.maxLevel);
	end
	if ( handles.maxLevel < 4 && handles.minLevel == 0 )	% Otherwise it was done above
		opt_A = sprintf('-A%.1f/%d/%d',handles.minArea, handles.minLevel, handles.maxLevel);
	end

	if (handles.IamCompiled),	opt_e = '-e';
	else						opt_e = '';
	end

	% Finally call the guy that really does the work
	[mask,tmp.head,tmp.X,tmp.Y] = grdlandmask_m(opt_R, opt_I, opt_D, opt_N, opt_A, opt_F, opt_V, opt_e);
    tmp.name = 'Landmask';		tmp.geog = 1;
	
	if (get(handles.check_isFloat,'Val') && ~isa(mask,'single'))	% User wants floats
		mask = single(mask);
	end
	if (isa(mask,'uint8'))
		nodes = unique(nodes);
		pal_1 = jet(numel(nodes));			% We only need these number of different colors
		pal_2 = zeros(max(nodes)+1,3);		% +1 because indices on palette are 1 based
		for (k = 1:numel(nodes))
			pal_2(nodes(k)+1,:) = pal_1(k,:);
		end
		tmp.cmap = pal_2;
	end
	mirone(mask,tmp)

% --------------------------------------------------------------------
function figure1_KeyPressFcn(hObject, eventdata)
% Check for "escape"
	if isequal(get(hObject,'CurrentKey'),'escape')
		handles = guidata(hObject);
		delete(handles.figure1);
	end

% --------------------------------------------------------------------
function grdlandmask_win_LayoutFcn(h1)
set(h1,...
'Color',get(0,'factoryUicontrolBackgroundColor'),...
'KeyPressFcn',@figure1_KeyPressFcn,...
'MenuBar','none',...
'Name','grdlandmask',...
'NumberTitle','off',...
'Position',[266 319 441 238],...
'Resize','off',...
'HandleVisibility','callback',...
'Tag','figure1');

uicontrol('Parent',h1, 'Position',[10 156 421 75], 'Style','frame', 'Tag','frame1');
uicontrol('Parent',h1, 'Position',[10 97 125 42],  'Style','frame', 'Tag','frame2');
uicontrol('Parent',h1, 'Position',[144 97 167 42], 'Style','frame', 'Tag','frame3');
uicontrol('Parent',h1, 'Position',[10 37 411 42],  'Style','frame', 'Tag','frame4');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[30 223 126 15],...
'String','Griding Line Geometry',...
'Style','text',...
'Tag','text_GLG');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','left',...
'Position',[77 192 80 21],...
'Style','edit',...
'Tag','edit_x_min');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','left',...
'Position',[163 192 80 21],...
'Style','edit',...
'Tag','edit_x_max');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','left',...
'Position',[77 166 80 21],...
'Style','edit',...
'Tag','edit_y_min');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','left',...
'Position',[163 166 80 21],...
'Style','edit',...
'Tag','edit_y_max');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'HorizontalAlignment','left',...
'Position',[22 196 55 15],...
'String','X Direction',...
'Style','text');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'HorizontalAlignment','left',...
'Position',[21 170 55 15],...
'String','Y Direction',...
'Style','text');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[183 213 41 13],...
'String','Max',...
'Style','text');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[99 213 41 13],...
'String','Min',...
'Style','text');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','left',...
'Position',[248 192 71 21],...
'Style','edit',...
'Tooltip','DX grid spacing',...
'Tag','edit_x_inc');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','left',...
'Position',[248 166 71 21],...
'Style','edit',...
'Tooltip','DY grid spacing',...
'Tag','edit_y_inc');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','center',...
'Position',[324 192 65 21],...
'Style','edit',...
'Tooltip','Number of columns in the grid',...
'Tag','edit_Ncols');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'HorizontalAlignment','center',...
'Position',[324 166 65 21],...
'Style','edit',...
'Tooltip','Number of rows in the grid',...
'Tag','edit_Nrows');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[265 214 41 13],...
'String','Spacing',...
'Style','text');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[332 214 51 13],...
'String','# of lines',...
'Style','text');

uicontrol('Parent',h1,...
'Call',@grdlandmask_win_uiCB,...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'Position',[400 165 21 48],...
'String','?',...
'Tag','push_Help_R_F_T');

uicontrol('Parent',h1,...
'FontName','Helvetica',...
'Position',[330 99 80 16],...
'String','Verbose ?',...
'Style','checkbox',...
'Tooltip','Display a waitbar showing computations advance',...
'Value',1,...
'Tag','check_verbose');

uicontrol('Parent',h1,...
'Call',@grdlandmask_win_uiCB,...
'FontName','Helvetica',...
'FontSize',9,...
'Position',[371 7 60 21],...
'String','OK',...
'Tag','push_OK');

uicontrol('Parent',h1,...
'FontName','Helvetica',...
'Position',[330 120 110 16],...
'String','Grid registration',...
'Style','checkbox',...
'Tooltip','If unchecked, it will use pixel registration',...
'Value',1,...
'Tag','check_gridReg');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[16 107 85 22],...
'String',{'crude'; 'low'; 'intermediate'; 'high'; 'full' },...
'Style','popupmenu',...
'Tooltip','Selects the resolution of the data set to use',...
'Value',1,...
'Tag','popup_resolution');

uicontrol('Parent',h1,...
'Call',@grdlandmask_win_uiCB,...
'FontName','Helvetica',...
'FontSize',9,...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'Position',[106 107 21 22],...
'String','?',...
'Tag','push_helpOptionD');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[18 131 105 15],...
'String','Coastline resolution',...
'Style','text',...
'Tag','text_Cr');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[148 106 50 21],...
'String','0',...
'Style','edit',...
'Tooltip','Features with an area smaller than this in km^2 will be ignored',...
'Tag','edit_opt_A');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[200 105 45 22],...
'String',{'0'; '1'; '2'; '3'; '4'},...
'Style','popupmenu',...
'Tooltip','Features of hierarchical level lower than this will be ignored',...
'Value',1,...
'Tag','popup_opt_A_minLevel');

uicontrol('Parent',h1,...
'Call',@grdlandmask_win_uiCB,...
'FontName','Helvetica',...
'FontSize',9,...
'FontWeight','bold',...
'ForegroundColor',[0 0 1],...
'Position',[285 105 21 22],...
'String','?',...
'Tag','push_helpOptionA');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[173 130 75 15],...
'String','Min area (-A)',...
'Style','text',...
'Tag','text_Ma');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[16 44 40 21],...
'String','0',...
'Style','edit',...
'Tooltip','Node value for Oceans (enter N for NaN)',...
'Tag','edit_ocean');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[57 44 40 21],...
'String','1',...
'Style','edit',...
'Tooltip','Node value for Land (enter N for NaN)',...
'Tag','edit_land');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[98 44 40 21],...
'String','0',...
'Style','edit',...
'Tooltip','Node value for Lakes (enter N for NaN)',...
'Tag','edit_lake');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[139 44 40 21],...
'String','1',...
'Style','edit',...
'Tooltip','Node value for Islands-in-lakes (enter N for NaN)',...
'Tag','edit_island');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[180 44 40 21],...
'String','0',...
'Style','edit',...
'Tooltip','Node value for Ponds-in-Islands-in-Lakes (enter N for NaN)',...
'Tag','edit_pond');

uicontrol('Parent',h1,...
'FontName','Helvetica',...
'Position',[235 47 80 16],...
'String','Boundary',...
'Style','checkbox',...
'Tooltip','If checked, nodes exactly on feature boundaries are considered outside [Default is inside]',...
'Tag','check_bdNodes');

uicontrol('Parent',h1,...
'FontName','Helvetica',...
'Position',[330 47 85 16],...
'String','Force float',...
'Style','checkbox',...
'Tooltip','If checked, result is always a matrix of single precision',...
'Tag','check_isFloat');

uicontrol('Parent',h1,...
'Enable','inactive',...
'FontName','Helvetica',...
'Position',[22 71 75 15],...
'String','Node values',...
'Style','text',...
'Tag','text_nodes');

uicontrol('Parent',h1,...
'BackgroundColor',[1 1 1],...
'Call',@grdlandmask_win_uiCB,...
'Position',[242 105 45 22],...
'String',{'0'; '1'; '2'; '3'; '4'},...
'Style','popupmenu',...
'Tooltip','Features of hierarchical level higher than this will be ignored',...
'Value',5,...
'Tag','popup_opt_A_maxLevel');

function grdlandmask_win_uiCB(hObject, eventdata)
% This function is executed by the callback and than the handles is allways updated.
	feval([get(hObject,'Tag') '_CB'],hObject, guidata(hObject));
