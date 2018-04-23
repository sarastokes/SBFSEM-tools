function varargout=cachedcall(varargin)
%% CACHEDCALL can be used to cache the results of slow function calls to disk
% 
% You can call an arbitrary function using CACHEDCALL. It will then check 
% if you have made the same call with the same arguments before. If you
% have then it will quickly load the previously computed results from the
% disk cache rather than calculating them again. If there are no matching
% calls in the cache, then the results will be calculated and saved in the
% cache.
%
% USAGE: [a,b,...]=cachedcall(fun[,Arguments,parameter,value])
%
% INPUTS: 
%    fun: handle to function whose outputs should be cached.
%    arguments: a cell with all the arguments that should be passed to fun.
%    
% Optional Named Parameters:
%   CacheFolder: the folder where the results are cached. The default folder
%                is the system temporary files folder (see tempdir)
%   MaxCacheSize: The maximum size of the cache before oldest cached
%                results will be deleted. (default=3e9)
%   SaveArguments: (default=false) this can be used to also save the input
%                arguments passed to the function in the cache
%   MaxAge:      discards cache if older than maxage - units are days.
%                (default=inf)
%   Tag:         A custom string that can be saved in the cache. displayed
%                when inspecting (default a string describing contents of Arguments)
%
% Further usage:
%   * cachedcall clear   - will empty the entire cache directory.
%   * cachedcall inspect - will inspect the contents of the cache.
%   * cachedcall clean   - will delete expired contents of the cache.
%                          Expired means older than MaxAge or the results
%                          of a function that has changed 
%
% Example 1: 
%    x=1e14+(1:50);
%    tic,isp1=isprime(x); normalcalltime=toc
%    tic,isp2=cachedcall(@isprime,x); firstcachedcalltime=toc
%    tic,isp3=cachedcall(@isprime,x); secondcachedcalltime=toc
%
% Example 2: cache the results of retrieving data from the web
%    tic
%    cachedcall(@urlread,'https://www.mathworks.com/moler/ncm/longley.dat')
%    toc
% 
%
% Relies on: <a href="http://www.mathworks.com/matlabcentral/fileexchange/31272-datahash">DataHash</a> by Jan Simon (included in download). 
% Improved performance if <a href="http://www.mathworks.com/matlabcentral/fileexchange/17476-typecast-and-typecastx-c-mex-functions">TypeCastX</a> by James Tursa installed (not required). 
%
% Aslak Grinsted 2015
% 6Mar2018 - SSP - small change to CacheFolder input parsing


p=inputParser;
p.addRequired('Function');
p.addOptional('Arguments',{},@(x)true);
p.addParameter('MaxAge',inf,@isnumeric);
p.addParameter('CacheFolder',tempdir,@isdir);
p.addParameter('MaxCacheSize',3e9,@isnumeric); %cache may get slightly bigger to allow for requested call. 
p.addParameter('SaveArguments',false,@islogical); %this can be enabled to allow for easier inspection of cache files 
p.addParameter('Tag','',@ischar); %this can be specified to allow for easier inspection of cache files contents
p.parse(varargin{:});
p=p.Results;

cachefiles=dir(fullfile(p.CacheFolder,'cc_*.mat'));
[~,ix]=sort(-cell2mat({cachefiles.datenum}));
cachefiles=cachefiles(ix);

if ~isa(p.Function,'function_handle')
    switch lower(p.Function)
        case 'inspect'
            fprintf('Inspecting cache (%s):\n',p.CacheFolder)
            if isempty(cachefiles), 
                fprintf('EMPTY\n');
                return
            end
            fprintf('%20s | %7s | %39s | %15s | %s\n','date','size','cachefile','function','tag')
            fprintf([repmat('-',1,100) '\n'])
            for ii=1:length(cachefiles)
                C=load(fullfile(p.CacheFolder,cachefiles(ii).name),'Tag','FunctionString');
                linktofile=sprintf('<a href="matlab: load(''%s'')">%s</a>',strrep(fullfile(p.CacheFolder,cachefiles(ii).name),'''',''''''),cachefiles(ii).name);
                fprintf('%20s | %5.1fMb | %39s | %15s | %s\n',datestr(cachefiles(ii).date,0),cachefiles(ii).bytes/(1024^2),linktofile,C.FunctionString,C.Tag)
            end
        case {'empty' 'clear'}
            delete(fullfile(p.CacheFolder,'cc_*.mat'))
            fprintf('Cache cleaned\n')
        case 'clean'
            fprintf('CLEANING CACHE:\n')
            for ii=1:length(cachefiles)
                try
                    C=load(fullfile(p.CacheFolder,cachefiles(ii).name),'FunctionDetails','MaxAge','CreatedDate','FunctionString','Tag');
                    if now-C.CreatedDate<C.MaxAge 
                        if all(getFunctionDateSize(C.FunctionDetails.file)==C.FunctionDetails.datesize);
                            continue
                        end
                    end
                    fprintf('DELETED: %20s | %5.1fMb | %39s | %15s | %s\n',datestr(cachefiles(ii).date,0),cachefiles(ii).bytes/(1024^2),cachefiles(ii).name,C.FunctionString,C.Tag)
                catch
                    fprintf('DELETED: %20s | %5.1fMb | %39s | Incompatible with this version of cachedcall. \n',datestr(cachefiles(ii).date,0),cachefiles(ii).bytes/(1024^2),cachefiles(ii).name)
                end
                delete(fullfile(p.CacheFolder,cachefiles(ii).name))
            end
            
        otherwise
            error('cachedcall:notAFunction','First input should be a function handle.')
    end
    return
    %TODO: switch commands for inspecting the cache/cleaning/emptying
end

if ~iscell(p.Arguments)
    p.Arguments={p.Arguments};
end


inhash=DataHash({p.Function p.Arguments});

hashfile=['cc_' inhash '.mat'];


ix=find(strcmp({cachefiles.name},hashfile));
if ~isempty(ix)
    filename=fullfile(p.CacheFolder,hashfile);
    d=dir(filename);
    if (now-d.datenum)<p.MaxAge
        try
            load(filename,'varargout','MaxAge','CreatedDate','FunctionDetails')
            if ~isinf(p.MaxAge), MaxAge=p.MaxAge; end; %override file maxage if maxage explicitly specified.
            if ((now-CreatedDate)<MaxAge) && all(getFunctionDateSize(FunctionDetails.file)==FunctionDetails.datesize) && length(varargout)>=nargout
                java.io.File(filename).setLastModified(java.lang.System.currentTimeMillis); %update last modified to current time (to ensure that it expires later)
                return
            end
        catch
            warning('Existing cache contents incompatible with this version of cachedcall.')
        end
    end
end

%CLEAN THE CACHE:
v=cumsum(cell2mat({cachefiles.bytes}));
ix=find(v>p.MaxCacheSize);
for ii=1:length(ix)
    delete(fullfile(p.CacheFolder,cachefiles(ix(ii)).name)); %DELETE THE OLDEST FILES UNTIL BELOW MAX CACHE SIZE
end

%--------- call the Function---------
Nout=nargout;
if Nout==0, Nout=nargout(p.Function); end
Nout=max(Nout,1);
varargout=cell(1,Nout);
[varargout{:}]=p.Function(p.Arguments{:});

%------------save to cache--------------
Tag=p.Tag;%#ok<NASGU>
if isempty(Tag)
    Tag=strtrim(evalc('disp(p.Arguments)')); Tag(Tag==10)=';';
end
FunctionString=char(p.Function); %#ok<NASGU>
CreatedDate=now;
MaxAge=p.MaxAge;
FunctionDetails=functions(p.Function);
FunctionDetails.datesize=getFunctionDateSize(FunctionDetails.file);
if p.SaveArguments
    Arguments=p.Arguments; %#ok<NASGU>
    save(fullfile(p.CacheFolder,hashfile),'varargout','Tag','FunctionString','CreatedDate','MaxAge','FunctionDetails','Arguments')
else    
    save(fullfile(p.CacheFolder,hashfile),'varargout','Tag','FunctionString','CreatedDate','MaxAge','FunctionDetails')
end



function dsz=getFunctionDateSize(fname)
dsz=[0 0];
if ~isempty(fname)
    d=dir(fname);
    dsz=[d.datenum d.bytes];
end