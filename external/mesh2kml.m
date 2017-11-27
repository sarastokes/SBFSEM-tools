function M = mesh2kml(varargin)
%Export textured geometry (surface or patch) to GoogleEarth as a KML and a
%Collada DAE files
% mesh2kml(...)     -surface or patch inputs, see bellow
% mesh2kml(...out)    -one common output filename or paths to {dae img kml}
% mesh2kml(...out,prp)  -Collada & GoogleEarth property value pairs
%  color:      color, default=[0.7 0.7 0.7] OR.. 
%              image, RGB(A)|BW(A)|filename (optional)
%  alpha:      opacity, default=[1] (opaque) OR..
%              image, BW|filename (optional)
%  latlon:     flag to interpret xyz as Lat,Lon,Alt, default=0
%  twosided:   flag to render faces from both sides, default=1
%  position:   [latitude_deg longitude_deg altitude_m]
%  altmode:    default='absolute', 'clampToGround', 'relativeToGround',
%              'relativeToSeaFloor', 'clampToSeaFloor'
%  orientation:[heading_NtoE pitch_NtoUp roll_UPtoE] (deg), default=[0,0,0]
%  scale:      [x y z] scale factors, default=[1,1,1]
%  camera:     [heading_deg tilt_deg range_m]
% M = mesh2kml(...)  -return final properties as struct
%Surface:
% mesh2kml(x,y,z...)   -NxM vertex coordinates
% mesh2kml(x,y,z,c...)   -NxMx3 face colors, last row & col ignored (TO DO)
% mesh2kml(x,y,z,u,v...)   -NxM texture coordinates
% mesh2kml(..,nx,ny,nz...)   -NxM vertex normals
% mesh2kml(S)             -above surface properties as struct
%Patch:
% mesh2kml(P...)  -patch properties as struct, with fields:
%  vertices: Nx3 vertex positions
%  faces:    Mx3 triangle faces (right hand rule)
%  normals:  Nx3 vertex normals (optional)
%  uv:       Nx2 texture coordinates for each vertex
%  
%Remarks:
%-Collada (dae) files can be dragged and dropped into GoogleEarth.
%-A kml file is written only if 'position' is provided.
%-For lat,lon 6dp gives ~15 cm precision at equator, 8dp is ~1.5 mm.
%-Textures wrap circularly if UV is outside the [0-1] range.
%-Texture pixels blend and image edge pixels blend with opposite edge.
%-If normals are not provided they are auto generated. Vertices shared by
% triangles get a smoothed normal using triangle area weighting.
%-To avoid normal smoothing when specifying a patch each vertex should be
% referenced by only one face.
%-Faces are auto generated using vertices(:,1:2), if missing.
%  
%Notes:
%-Altitude exaggeration in GoogleEarth will affect the model's origin.
%-The only way to visualise textured polygons in MatLab is to draw each
% polygon as a quad with its own image chip, which is very limiting.
%-To generate dae template draw a polygon in Google SketchUp 2017 > export
% as kmz > open kmz with winzip > extract dae file > modify as needed.
%-SketchUp duplicates all polygons to face both ways, but mesh2kml uses an
% undocumented Collada tag: <effect><extra><technique><double_sided>.
%-SketchUp can export a quad mesh dae but they don't work in GoogleEarth.
%-GoogleEarth ignores camera references in dae file.
%  
%To do:
%-Allow one colour per face, see surf2patch.
%-Allow multi patch input using array of structures as input.
%-Allow quad patch input by converting it to a tri patch.
%-Allow input to be a handle to a displayed surface or patch object.
%-Allow export as kmz file.
%-Use ridge detection when triangulating surfaces.
%-Test generated normals.
%-Add more patch examples.
%-Remove thin triangles from patch inputs.
%  
%Ex1: peaks - surface, one colour, with alpha
% [x,y,z] = peaks;
% mesh2kml(x*4,y*4,z,'peaks','color','red','position',[-33.85622 151.21535 10],'alpha',0.7);
%  
%Ex2: cylinder - surface, textured, scaled
% [x,y,z] = cylinder;
% [v,u] = ndgrid(linspace(0,1,size(x,1)),linspace(0,1,size(x,2)));
% mesh2kml(x,y,z,u,v,'cylinder','col','peppers.png','pos',[-33.85622 151.21535 15],'scale',[3 3 10],'cam',[180 60 30]);
%  
%Ex3: sky - surface, latlon mode, textured, with alpha
% [lat,lon,alt] = ndgrid(-90:5:90,-180:5:180,500000);
% [v,u] = ndgrid(linspace(0,1,size(lat,1)),linspace(0,1,size(lon,2)));
% c = checkerboard(50,90/5,180/5);
% mesh2kml(lat,lon,alt,u,v,'sky','latlon',1,'col',c,'alp',c);
%  
%Ex4: mountain - patch, latlon mode, one colour
% load seamount  %load lon,lat,alt scatter points on a amountain
% mesh2kml('mount','vert',[y x (z-min(z))*10],'latlon',1,'col','g','cam',[0 45]);
%  
%Ex5: more patch examples needed..
%  
%See also: surf, patch, surf2patch, delaunay, geodetic2ecef, ecef2lv
% http://www.collada.org/2005/11/COLLADASchema
% http://blender.stackexchange.com/questions/3778/why-does-the-collada-exporter-not-export-texture-references
 
%Sergey Kharabash 2017
%Email bugs, enhancements, requests to: s3rg3y@hotmail.com
 
%parse inputs
[M,out] = parseinputs(varargin);
 
%output files
if ischar(out) %one common file path (no extension)
    dae_file = [out '.dae']; %output Collada geometry file
    img_file = [out '.png']; %output image file (if needed)
    kml_file = [out '.kml']; %output GoogleEarth file (if needed)
else
    [dae_file,img_file,kml_file] = out{:}; %custom paths (with extensions)
end
 
%write dae file (may point at an image file)
if fld(M,'vertices') || fld(M,'z')
    M = daeWrite(M,img_file,dae_file);
end
 
%write kml file that points at dae file
if fld(M,'position')
    M = kmlWrite(M,dae_file,kml_file);
end
 
%outputs
if ~nargout
    clear M
end
 
function [M,out] = parseinputs(args)
%convert inputs to a struct with the following fields:
p ={'x' 'y' 'z' 'c' 'u' 'v' 'nx' 'ny' 'nz' ...  %surface parameters
    'vertices' 'faces' 'uv' 'normals' ...       %patch parameters
    'color' 'alpha' 'twosided' 'latlon' ...     %common parameters
    'position' 'altmode' 'scale' 'orientation' 'camera'}; %kml parameters
    %'Location' 'FaceColor' 'FaceAlpha' 'FaceCData' 'facevertexcdata'}; %alternate names (TO DO)
if isstruct(args{1}) %mesh2kml(M,out..) -input is as struct
    M = args{1};
    f = fieldnames(M);
    for k = 1:numel(f) %check field names
        if ~any(strcmp(p,f{k}))
            i = strncmpi(p,f{k},numel(f{k})); %match start of string
            if sum(i)>1
                i = strcmpi(p,f{k}); %match whole string
            end
            if sum(i)==1 && ~isfield(M,p{i}) %rename field
                M.(p{i}) = M.(f{k});
                M.(f{k}) = [];
            end
        end
    end
    out = args{2};
    prop = args(3:end); %parameter value paris
else %mesh2kml(x,y..,out..) -input is a surface as arrays
    out_idx = find(~cellfun(@isnumeric,args),1); %find output file name(s) argument
    switch out_idx-1
        case 0, f = {};  %mesh2kml(out..) allow empty input
        case 1, f = {'z'};
        case 3, f = {'x' 'y' 'z'};
        case 6, f = {'x' 'y' 'z' 'nx' 'ny' 'nz'};
        case 5, f = {'x' 'y' 'z' 'u' 'v'};
        case 8, f = {'x' 'y' 'z' 'u' 'v' 'nx' 'ny' 'nz'};
        %case 2, f = {'z' 'c'};                          %TO DO
        %case 4, f = {'x' 'y' 'z' 'c'};                  %TO DO
        %case 7, f = {'x' 'y' 'z' 'c' 'nx' 'ny' 'nz'};   %TO DO
        otherwise, error('error')
    end
    M = cell2struct(args(1:out_idx-1),f,2);
    out = args{out_idx};
    prop = args(out_idx+1:end); %parameter value pairs
end
for k = 1:2:numel(prop) %append parameter value pairs to struct
    i = strncmpi(p,prop{k},numel(prop{k})); %match start of string
    if sum(i)>1
        i = strcmpi(p,prop{k}); %match whole string
    end
    assert(sum(i)==1,'mesh2kml:FindObjFailed','Invalid property: %s',prop{k})
    M.(p{i}) = prop{k+1}; %add argument to struct
end
 
function M = daeWrite(M,img_file,dae_file)
%checks
if ~fld(M,'vertices') %convert surface to patch
    if ~fld(M,'x')
        [M.x,M.y] = ndgrid(linspace(-1,1,size(M.z,1)),linspace(-1,1,size(M.z,1))); %default x,y
    end
    [M.faces,M.vertices] = surf2patch(M.x,M.y,M.z,'tri'); %triangulate
    [~,j,k] = unique(M.vertices,'rows','stable'); %check for repeated vertices
    M.vertices = M.vertices(j,:); %remove repeated vertices
    M.faces = k(M.faces); %fix pointers to removed vertices
    M.faces(any(diff(sort(M.faces,2),[],2)==0,2),:) = []; %remove thin faces
elseif ~fld(M,'faces') %define patch faces by triangulating on x,y
    M.faces = delaunay(M.vertices(:,1),M.vertices(:,2));
end
if fld(M,'latlon') && M.latlon==1 %interpret x,y,z as lat,lon,alt
    if ~fld(M,'position')
        M.position(1) = mean(M.vertices(:,1)); %use mean lat,lon and min alt as x,y,z origin
        M.position(2) = mean(M.vertices(:,2));
        M.position(3) = min (M.vertices(:,3));
    end
    [   M.vertices(:,1),M.vertices(:,2),M.vertices(:,3)] = geodetic2lv(... %convert lat,lon,alt to x,y,z
        M.vertices(:,1),M.vertices(:,2),M.vertices(:,3),...
        M.position( 1),M.position( 2),M.position( 3));
end
if ~fld(M,'uv') && fld(M,'u') && fld(M,'v')
    M.uv = [M.u(:) M.v(:)];
end
textured = fld(M,'uv'); %is object textured or coloured
if textured
    if fld(M,'color') && ischar(ColorSpec(M.color)) %color can be an image file name
        [M.color,map,M.alpha] = imread(M.color);
        if ~isempty(map) %image may be indexed
            M.color = ind2rgb(M.color,map);
        end
    end
else
    if     ~fld(M,'color'),   M.color = [0.7 0.7 0.7];      %default colour
    elseif isinteger(M.color),M.color = im2double(M.color); %convert 0-255 to 0-1
    elseif ischar(M.color),   M.color = ColorSpec(M.color); %convert say 'r' to [1 0 0]
    end
end
if ~fld(M,'alpha') && numel(M.color)==4 %color(4) can set alpha
    M.alpha = M.color(4);
    M.color = M.color(1:3);
end
if ~fld(M,'twosided')
    M.twosided = 1; %default
end
if ~fld(M,'normals')
    M.normals = patchnormals(M); %smooth normals (area weighted)
end
M.normals = M.normals; %Collada uses right-hand-rule, MatLab uses left
 
%write dae file
n = 10; %new line character, linux:10  win:[10 13]
f = fopen(dae_file,'w'); %open dae file for writing
t = datestr(now+java.util.Date().getTimezoneOffset()/24/60,'yyyy-mm-ddTHH:MM:SSZ'); %utc time stamp
wr = @(x)fwrite(f,x,'char'); %function to write text to file
wr(['<?xml version="1.0" encoding="UTF-8" standalone="no" ?>' n...
    '<COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema" version="1.4.1">' n...
    '    <asset>' n...
    '        <contributor>' n...
    '            <authoring_tool>MatLab ' version '</authoring_tool>' n...
    '        </contributor>' n...
    '        <created>' t '</created>' n...
    '        <modified>' t '</modified>' n...
    '        <unit meter="1" name="meter" />' n...
    '        <up_axis>Z_UP</up_axis>' n...
    '    </asset>' n...
    '    <library_visual_scenes>' n...
    '        <visual_scene id="VISUAL_SCENE">' n...
    '            <node name="MatLab">' n...
    '                <instance_geometry url="#GEOMETRY">' n...
    '                    <bind_material>' n...
    '                        <technique_common>' n...
    '                            <instance_material symbol="MATERIAL_SYMBOL" target="#MATERIAL">' n...
    '                                <bind_vertex_input semantic="UV" input_semantic="TEXCOORD" input_set="0" />' n...
    '                            </instance_material>' n...
    '                        </technique_common>' n...
    '                    </bind_material>' n...
    '                </instance_geometry>' n...
    '            </node>' n...
    '        </visual_scene>' n...
    '    </library_visual_scenes>' n...
    '    <library_geometries>' n...
    '        <geometry id="GEOMETRY">' n...
    '            <mesh>' n...
    '                <source id="POSITION">' n...
    '                    <float_array id="VERTEX_DATA" count="' num2str(numel(M.vertices)) '">' n]);
fprintf(f,'%.9g %.9g %.9g\n',M.vertices'); %vertices (9sf)
wr(['                    </float_array>' n...
    '                    <technique_common>' n...
    '                        <accessor count="' num2str(size(M.vertices,1)) '" source="#VERTEX_DATA" stride="3">' n...
    '                            <param name="X" type="float" />' n...
    '                            <param name="Y" type="float" />' n...
    '                            <param name="Z" type="float" />' n...
    '                        </accessor>' n...
    '                    </technique_common>' n...
    '                </source>' n...
    '                <source id="NORMAL">' n...
    '                    <float_array id="NORMAL_DATA" count="' num2str(numel(M.normals)) '">' n]);
fprintf(f,'%.4g %.4g %.4g\n',M.normals'); %normals (4sf) OR
wr(['                    </float_array>' n...
    '                    <technique_common>' n...
    '                        <accessor count="' num2str(size(M.normals,1)) '" source="#NORMAL_DATA" stride="3">' n...
    '                            <param name="X" type="float" />' n...
    '                            <param name="Y" type="float" />' n...
    '                            <param name="Z" type="float" />' n...
    '                        </accessor>' n...
    '                    </technique_common>' n...
    '                </source>' n]);
if textured
    wr(['                <source id="TEXTURE">' n...
        '                    <float_array id="TEXTURE_DATA" count="' num2str(numel(M.uv)) '">' n]);
    fprintf(f,'%.6g %.6g\n',M.uv');
    wr(['                    </float_array>' n...
        '                    <technique_common>' n...
        '                        <accessor source="#TEXTURE_DATA" stride="2">' n...
        '                            <param name="S" type="float" />' n...
        '                            <param name="T" type="float" />' n...
        '                        </accessor>' n...
        '                    </technique_common>' n...
        '                </source>' n]);
end
wr(['                <vertices id="verts">' n...
    '                    <input semantic="POSITION" source="#POSITION" />' n...
    '                    <input semantic="NORMAL" source="#NORMAL" />' n...
    '                </vertices>' n...
    '                <triangles count="' num2str(numel(M.faces)/3) '" material="MATERIAL_SYMBOL">' n...
    '                    <input offset="0" semantic="VERTEX" source="#verts" />' n]);
if textured
    wr(['                    <input offset="1" semantic="TEXCOORD" source="#TEXTURE" />' n]);
end
wr(['                    <p>' n]);
if textured
    fprintf(f,'%.0f %.0f %.0f %.0f %.0f %.0f\n',M.faces(:,[1 1 2 2 3 3])'-1); %Colada uses base zero
else
    fprintf(f,'%.0f %.0f %.0f\n',M.faces'-1); %Colada uses base zero
end
wr(['                    </p>' n...
    '                </triangles>' n...
    '            </mesh>' n...
    '        </geometry>' n...
    '    </library_geometries>' n...
    '    <library_materials>' n...
    '        <material id="MATERIAL">' n...
    '            <instance_effect url="#EFFECT" />' n...
    '        </material>' n...
    '    </library_materials>' n...
    '    <library_effects>' n...
    '        <effect id="EFFECT">' n...
    '            <profile_COMMON>' n]);
if textured
    wr(['                <newparam sid="SURFACE">' n...
        '                    <surface type="2D">' n...
        '                        <init_from>IMAGE</init_from>' n...
        '                    </surface>' n...
        '                </newparam>' n...
        '                <newparam sid="surfaceTex">' n...
        '                    <sampler2D>' n...
        '                        <source>SURFACE</source>' n...
        '                    </sampler2D>' n...
        '                </newparam>' n]);
end
wr(['                <technique sid="COMMON">' n...
    '                    <lambert>' n...
    '                        <diffuse>' n]);
if textured
    wr(['                            <texture texture="surfaceTex" texcoord="UV" />' n]);
else
    wr(['                            <color>' sprintf('%g ',M.color) '</color>' n]);
end
wr(['                        </diffuse>' n]);
if fld(M,'alpha') && numel(M.alpha)==1 %alpha works for textured and colored objects
    wr(['                         <transparent opaque="A_ONE">' n...
        '                             <color>0 0 0 ' sprintf('%g',M.alpha) '</color>' n...
        '                         </transparent>' n...
        '                         <transparency>' n...
        '                             <float>1</float>' n...
        '                         </transparency>' n]);
end
wr(['                    </lambert>' n...
    '                </technique>' n...
    '            </profile_COMMON>' n...
    '            <extra>' n...
    '                <technique>' n...
    '                    <double_sided>' num2str(M.twosided) '</double_sided>' n...
    '                </technique>' n...
    '            </extra>' n...
    '        </effect>' n...
    '    </library_effects>' n]);
if textured
    wr(['    <library_images>' n...
        '        <image id="IMAGE">' n...
        '            <init_from>' img_file '</init_from>' n...
        '        </image>' n...
        '    </library_images>' n]);
end
wr(['    <scene>' n...
    '        <instance_visual_scene url="#VISUAL_SCENE" />' n...
    '    </scene>' n...
    '</COLLADA>' n]);
fclose(f); %close file
 
%write image data to file (if needed and provided)
if textured && fld(M,'color')
    if any(size(M.color,3) == [1 3])
        if ~fld(M,'alpha') || numel(M.alpha)==1
            imwrite(M.color,img_file); %bw or rgb
        else
            imwrite(M.color,img_file,'alpha',im2uint8(M.alpha)); %with alpha
        end
    elseif any(size(M.color,3) == [2 4])
        imwrite(M.color(:,:,1:end-1),img_file,'alpha',im2uint8(M.color(:,:,end))); %with alpha
    end
end
 
function M = kmlWrite(M,dae,kml)
%Write kml file that points at a Collada dae geometry file
%checks
if ~fld(M,'altitudeMode'),M.altitudeMode = 'absolute'; end %altitude mode
if ~fld(M,'orientation'), M.orientation = [0 0 0];     end %heading,pitch,roll
if ~fld(M,'scale'),       M.scale = 1;                 end %object scale factor
if ~fld(M,'camera'),      M.camera = [];               end %camera range
if numel(M.position)==2
    M.position(3) = 0; %altitude
end
if numel(M.scale)==1
    M.scale = [M.scale M.scale M.scale]; %xyz scale factors
end
if any(numel(M.camera)==[0 1]) %default camera heading,tilt
     M.camera = [[0 45]+M.orientation(1:2) M.camera]; %adjust for model heading and pitch
end
if numel(M.camera)==2 %default camera range
    if fld(M,'vertices')
        M.camera(3) = max(range(M.vertices).*M.scale)*2; %measure object and adjust for scale
    else
        M.camera(3) = 40; %default
    end 
end
M.position(2) = mod(M.position(2)+180,360)-180; %wrap longitude [-180 to 180)
 
%main
n = char(10); %line feed character
[~,name] = fileparts(dae); %name object same as dae file name, no extension
f = fopen(kml,'w'); %create kml output file
pause(0.2)
fwrite(f,[...
    '<?xml version="1.0" encoding="UTF-8"?>' n...
    '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">' n...
    '<Placemark>' n...
    '   <name>' name '</name>' n...
    '   <LookAt>' n...
    '       <longitude>' num2str(M.position(2),'%.8f') '</longitude>' n...
    '       <latitude>'  num2str(M.position(1),'%.8f') '</latitude>'  n...
    '       <altitude>'  num2str(M.position(3),'%.8f') '</altitude>'  n...
    '       <heading>'   num2str(M.camera(1),'%.6f') '</heading>' n...
    '       <tilt>'      num2str(M.camera(2),'%.6f') '</tilt>' n...
    '       <range>'     num2str(M.camera(3),'%.2f') '</range>' n...
    '       <altitudeMode>' M.altitudeMode '</altitudeMode>' n...
    '   </LookAt>' n...
    '   <Model>' n...
    '       <altitudeMode>' M.altitudeMode '</altitudeMode>' n...
    '       <Location>' n...
    '           <latitude>'  num2str(M.position(1),'%.8f') '</latitude>'  n...
    '           <longitude>' num2str(M.position(2),'%.8f') '</longitude>' n...
    '           <altitude>'  num2str(M.position(3),'%.8f') '</altitude>'  n...
    '       </Location>' n...
    '       <Orientation>' n...
    '           <heading>' num2str(M.orientation(1),'%.6f') '</heading>' n...
    '           <tilt>'    num2str(M.orientation(2),'%.6f') '</tilt>' n...
    '           <roll>'    num2str(M.orientation(3),'%.6f') '</roll>' n...
    '       </Orientation>' n...
    '       <Scale>' n...
    '           <x>' num2str(M.scale(1),'%.8g') '</x>' n...
    '           <y>' num2str(M.scale(2),'%.8g') '</y>' n...
    '           <z>' num2str(M.scale(3),'%.8g') '</z>' n...
    '       </Scale>' n...
    '       <Link>' n...
    '           <href>' dae '</href>' n...
    '       </Link>' n...
    '   </Model>' n...
    '</Placemark>' n...
    '</kml>' n]);
fclose(f); %close file
 
function N = patchnormals(M)
%Create smoothed vertex normals (area weighted, left-hand-rule, normalised)
% N = patchnormals(M)  -struct with fields: faces Mx3, vertices Nx3
%N: vertex normals nx3
A = M.faces(:, 1 ); %face corners index
B = M.faces(:, 2 );
C = M.faces(:,end); %might work for quads also, needs testing
fn = cross(M.vertices(A,:)-M.vertices(B,:),M.vertices(C,:)-M.vertices(A,:),2); %face normals, area weighted
N = zeros(size(M.vertices)); %init vertex normals
for i = 1:size(M.faces,1) %step through faces
    N(A(i),:) = N(A(i),:)+fn(i,:); %accumulate face normals for each vertex
    N(B(i),:) = N(B(i),:)+fn(i,:);
    N(C(i),:) = N(C(i),:)+fn(i,:);
end
N = bsxfun(@rdivide,N,sqrt(sum(N.^2,2))); %normalise
 
function c = ColorSpec(c)
switch lower(c(1))
    case 'y', c = [1 1 0]; %yellow
    case 'm', c = [1 0 1]; %magenta
    case 'c', c = [0 1 1]; %cyan
    case 'r', c = [1 0 0]; %red
    case 'g', c = [0 1 0]; %green
    case 'b', c = [0 0 1]; %blue
    case 'w', c = [1 1 1]; %white
    case 'k', c = [0 0 0]; %black
    otherwise %returns input string
end
 
function [x,y,z] = geodetic2lv(lat,lon,alt,LAT,LON,ALT)
%Convert geodetic to local vertical
% [x,y,z] = geodetic2lv(lat,lon,alt,LAT,LON,ALT)  -location & origin (deg,m)
el = almanac('earth','ellipsoid','m','wgs84'); %ellipsoid
[x,y,z] = geodetic2ecef(lat*pi/180,lon*pi/180,alt,el);
[x,y,z] = ecef2lv(x,y,z,LAT*pi/180,LON*pi/180,ALT,el);
 
function tf = fld(M,f) %test if field exists and is not empty
tf = isfield(M,f) && ~isempty(M.(f));