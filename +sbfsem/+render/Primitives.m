classdef Primitives < handle
% 7Sept2018 - SSP - updated namespace
    
	properties (Constant = true, Hidden = true)
		SPHERE_DIV = 10;
		CYLINDER_DIV = 8;
		TOPFACEDIAM = 1;
	end

	methods
		function obj = Primitives()
			% Do nothing
		end
	end

	methods (Static)
		function [pointOrder, pointList] = Cuboid()
			pointOrder = 0:7;
			pointList = [[0, 0, 0]; [1, 0, 0]; [1, 1, 0]; [0, 1, 0];
						 [0, 0, 1]; [1, 0, 1]; [1, 1, 1]; [0, 1, 1]];
			pointList = bsxfun(@plus, [0, -0.5, -0.5], pointList);
		end

		function [cellList, pointList] = Cylinder(div, topFaceDiam)
			if nargin < 2
				topFaceDiam =sbfsem.render.Primitives.TOPFACEDIAM;
			end

			if nargin < 1
				div =sbfsem.render.Primitives.CYLINDER_DIV;
			end

			pointList = [];
			points = [];

			for i = 0:div-1
				theta = i / div * 2 * pi;
				pointList = cat(1, pointList,...
					[0, 0, 0], [0, cos(theta), sin(theta)]);
				points = cat(2, points, [numel(points), numel(points)+1]);
			end
			points = cat(2, points, [0, 1]);

			for i = 0:div-1
				theta = i / div * 2 * pi;
				pointList = cat(1, pointList, [0, cos(theta), sin(theta)]);
				pointList = cat(1, pointList,...
					[1, cos(theta)*topFaceDiam, sin(theta)*topFaceDiam]);
				points = cat(2, points, [div*2 + i*2, div*2 + 1 + i*2]);
			end
			points = cat(2, points, [div*2, div*2 + 1]);

			for i = 0:div-1
				theta = i / div * 2 * pi;
				pointList = cat(1, pointList, [1, 0, 0]);
				pointList = cat(1, pointList,...
					[1, cos(theta)*topFaceDiam, sin(theta)*topFaceDiam]);
				points = cat(2, points, [div*2*2 + i*2, div*2*2 + 1 + i*2]);
			end
			points = cat(2, points, [div*2*2, div*2*2 + 1]);

			cellList = struct('type', 6, 'points', points);
		end

		function [cellList, pointList] = Cylinder3Cell(div, topFaceDiam)
			if nargin < 2
				topFaceDiam =sbfsem.render.Primitives.TOPFACEDIAM;
			end

			if nargin < 1
				div =sbfsem.render.Primitives.CYLINDER_DIV;
			end

			cellList = [];
			pointList = [];

			points = [];
			for i = 0:div-1
				theta = i / div * 2 * pi;
				pointList = cat(1, pointList, [0, 0, 0]);
				pointList = cat(1, pointList, ...
					[0, cos(theta), sin(theta)]);
				points = cat(2, points, [numel(points), numel(points) + 1]);
			end
			points = cat(2, points, [0, 1]);
			cellList = cat(1, cellList, struct('type', 6, 'points', points));

			points = [];
			for i = 0:div-1
				theta = i / div * 2 * pi;
				pointList = cat(1, pointList, [0, cos(theta), sin(theta)]);
				pointList = cat(1, pointList,...
					[1, cos(theta)*topFaceDiam, sin(theta)*topFaceDiam]);
				points = cat(2, points, [div*2 + i*2, div*2 + 1 + i*2]);
			end
			points = cat(2, points, [div*2, div*2 + 1]);
			cellList = cat(1, cellList, struct('type', 6, 'points', points));

			points = [];
			for i = 0:div-1
				theta = i / div * 2 * pi;
				pointList = cat(1, pointList, [1, 0, 0]);
				pointList = cat(1, pointList, ...
					[1, cos(theta)*topFaceDiam, sin(theta)*topFaceDiam]);
				points = cat(2, points, [div*2*2 + i*2, div*2*2 + 1 + i*2]);
			end
			points = cat(2, points, [div*2*2, div*2*2 + 1]);
			cellList = cat(1, cellList, struct('type', 6, 'points', points));
		end

		function [cellList, pointList] = BaseSphere(div)
			if nargin < 1
				div = sbfsem.render.Primitives.SPHERE_DIV;
			end

			cellList = [];
			pointList = [];

			for i = 0:div
				ph = pi * i / div;
				y = cos(ph);
				r = sin(ph);
				for j = 0:div-1
					th = 2 * pi * j / div;
					x = r * cos(th);
					z = r * sin(th);

					pointList = cat(1, pointList, [x, y, z]);
				end
			end

			for i = 0:div-1
				points = [];
				for j = 0:div-1
					points = cat(2, points, [i*div+j, (i+1)*div+j]);
				end
				points = cat(2, points, [i*div, (i+1)*div]);
                cellList = cat(1, cellList,...
                    struct('type', 6, 'points', points));
			end
        end

        function [cells, pointList] = Sphere(varargin)
        	% SPHERE
        	%
        	% Inputs:
        	%	pos 		[0, 0, 0] 	Value to translate sphere by
        	%	size 		1 			Value to scale sphere by
        	%	data 		[] 			Data attached to cell
        	%	pointStart 	0			Amount to shift start points by
        	% ---------------------------------------------------------
            ip = inputParser();
            ip.CaseSensitive = false;
            addParameter(ip, 'pos', [0, 0, 0], @isvector);
            addParameter(ip, 'data', []);
            addParameter(ip, 'Size', 1, @isnumeric);
            addParameter(ip, 'PointStart', 0, @isnumeric);
            parse(ip, varargin{:});
            position = ip.Results.pos;

			[cells, pointList] = sbfsem.render.Primitives.BaseSphere();

			for i = 1:numel(cells)
				cells(i).points = bsxfun(@plus,...
					ip.Results.PointStart, cells(i).points);
				cells(i).data = ip.Results.data;
			end

			% Scale
			pointList = ip.Results.Size * pointList;
			% Translate
			pointList = bsxfun(@plus, position, pointList);
		end

		function [cellList, pointList] = Hemisphere(div)
			if nargin < 1
				div =sbfsem.render.Primitives.SPHERE_DIV;
			end

			cellList = [];
			pointList = [];

			for i = 0:(div/2)
				ph = pi * i / div;
				y = cos(ph);
				r = sin(ph);
				for j = 0:div-1
					th = 2 * pi * j / div;
					x = r * cos(th);
					z = r * sin(th);

					pointList = cat(1, pointList, [x, y, z]);
				end
			end

			for i = 0:(div/2)-1
				points = [];
				for j = 0:div-1
					points = cat(1, points, [i*div + j, (i+1)*div + j]);
				end
				points = cat(1, points, [i*div, (i+1)*div]);
				cellList = cat(1, cellList, struct('type', 6, 'points', points));
			end
        end

        function [cellList, pointList] = HemisphereCylinder(varargin)

        	cellList = [];
        	pointList = [];
        	pointStart = 0;

        	ip = inputParser();
        	ip.CaseSensitive = false;
        	addParameter(ip, 'div',sbfsem.render.Primitives.CYLINDER_DIV, @isnumeric);
        	addParameter(ip, 'topFaceDiam', 1, @isnumeric);
        	addParameter(ip, 'Height', 1, @isnumeric);
        	addParameter(ip, 'Radius', 1, @isnumeric);
        	parse(ip, varargin{:});
        	div = ip.Results.div;
        	topFaceDiam = ip.Results.topFaceDiam;
        	radius = ip.Results.Radius;
        	height = ip.Results.Height;

        	% Hemisphere point list
        	for i = 0:round(div/2)  
        		% Angles in radians for 0 to pi/2
        		ph = pi * i / div;
        		y = cos(ph);
        		r = sin(ph);
        		for j = 0:div-1
        			th = 2 * pi * j / div;
        			x = r * cos(th);
        			z = r * sin(th);

        			pointList = cat(1, pointList,...
        				[-y*radius, z*radius, x*radius]);
        			pointStart = pointStart + 1;
        		end
        	end

        	% Hemisphere cell list
        	for i = 0:round(div/2)
        		points = [];
        		for j = 0:div-1
        			points = cat(2, points, [i*div+j, (i+1)*div+j]);
        		end
        		points = cat(2, points, [i*div, (i+1)*div]);
        		cellList = cat(1, cellList,...
        			struct('type', 6, 'points', points));
        	end

        	% Cylinder point list
        	point_list = [];
        	for i = 0:div-1
        		theta = i / div * 2 * pi;
        		point_list = cat(1, point_list,...
        			[0, cos(theta)*radius, sin(theta)*radius]);
        		point_list = cat(1, point_list,...
        			[height, cos(theta)*topFaceDiam*radius,...
        			 	sin(theta)*topFaceDiam*radius]);
        	end

        	cellList = cat(1, cellList);
        end

		function [localCells, localPoints] = Line(pt1, pt2, data, pointStart)
			if nargin < 1
				pt1 = [0, 0, 0];
			end
			if nargin < 2
				pt2 = [0, 0, 0];
			end
			if nargin < 3
				data = 0;
			end
			if nargin < 4
				pointStart = 0;
			end

			localPoints = [pt1; pt2];
			localCells = struct('type', 3, 'data', data,...
				'points', [0+pointStart, 1+pointStart]);
		end
	end
end