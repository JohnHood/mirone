function [mask, head, X, Y] = c_grdlandmask(varargin)
% Temporary function to easy up transition from GMT4 to GMT5.2

% $Id: c_grdlandmask.m 9840 2016-10-03 01:18:59Z j $

	global gmt_ver
	if (isempty(gmt_ver)),		gmt_ver = 4;	end		% For example, if calls do not come via mirone.m
	
	if (gmt_ver == 4)
		if (nargout == 1)
			mask = grdlandmask_m(varargin{:});
		elseif (nargout == 4)
			[mask, head, X, Y] = grdlandmask_m(varargin{:});
		else
			error('Wrong number of output args')
		end
	else
		cmd = 'grdlandmask';
		for (k = 1:numel(varargin))
			cmd = sprintf('%s %s', cmd, varargin{k});
		end
		mask = gmtmex(cmd);
		gmtmex('destroy')
		if (nargout > 1)
			head = [mask.range mask.registration mask.inc];	X = mask.x;		Y = mask.y;
		end
		mask = mask.z;
	end
