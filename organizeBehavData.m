function  organizeBehavData ()
% OrgData is meant to combine experimental metadata with classification 
% values calculated by JAABA seperate data on a per fly basis 
% (JAABA: The Janelia Automatic Animal Behavior Annotator
% Copyright 2012, Kristin Branson, HHMI Janelia Farm Resarch Campus)

% **The following file structure is expected to exist:
% expfolder/datefolder/moviefolder/trackingfolder/JAABAfolder/

%INPUTS are queried: First, the experimental folder - expfolder
%Second, the excel file containing per-fly metadata - infofile
    % Required fieldnames for excel file (order doesn't matter): 
    % "movies" -contains movie folder name
    % "fly" - index of fly assigned by tracker
    % "genotype" - integer or character differentiating flies of different kinds
    
    % Optional filednames for excel file: 
    % "fps" - frames per second of movie file
    % "frameshift" - amount (pos or neg) to shift frames,
    % vararg - can input any other metadata you care about
    
% OUTPUT: flymatAll - saved mat file containing metadata and scores data for
%                     each fly


% Query user for experiment folder and info file
expfolder = uigetdir('','Select Experiment Folder'); 
cd(expfolder);
infofile = uigetfile('*.xlsx','Select Info File'); 

% Organize data into a structure
[scoresgalore,info] = makeScoreStruct(expfolder,infofile);

% Now organize data by fly
cnt=0;

% Loop through each movie file listed in infofile
for n=1:size(scoresgalore,2)
    index = scoresgalore(n).index;
    
    % Loop through each fly's data
    for s=1:length(index) % #flies per movie
        ind = index(s);
        cnt=cnt+1;
        vnames = info.Properties.VariableNames; % var names in infofile
        
        % Make variables in infofile fields in flymat structure
        for t=1:length(vnames);
            matname = strcat('flymat.',vnames(t));
            evalc([matname{1},' = info.',vnames{t},'(ind)']);
        end
       
        % Extract field names of data that was scored
        scorefields = fieldnames(scoresgalore);
        temp = [];
        for i = 1:length(scorefields)
            if strcmp(scorefields(i),'movie') || strcmp(scorefields(i),'index')
                temp(i) = 1;
            else
                temp(i) = 0;
            end
        end
        scorefields(find(temp)) = [];
        
        % Extract scored data for each fly and calculate total # of bouts,
        % total duration of bouts, and binned bout # and duration for each
        % minute (if sampling frequency is given in infofile as fps)
        for i = 1:length(scorefields)
            if ~isempty(scoresgalore(n).(scorefields{i})) % check if scores are there
                if length(scoresgalore(n).(scorefields{i}).t0s) < s
                    disp('WARNING: Number of flies specified in info file does not match number of flies tracked')
                end
                flymat.([scorefields{i},'_start']) = scoresgalore(n).(scorefields{i}).t0s{s};
                flymat.([scorefields{i},'_end']) = scoresgalore(n).(scorefields{i}).t1s{s};
                flymat.([scorefields{i},'_startsm']) = scoresgalore(n).(scorefields{i}).startsm{s};
                flymat.([scorefields{i},'_endsm']) = scoresgalore(n).(scorefields{i}).endsm{s};
                flymat.([scorefields{i},'_binary']) = scoresgalore(n).(scorefields{i}).binary{s};
                flymat.([scorefields{i},'_bouts']) = length(scoresgalore(n).(scorefields{i}).endsm{s});
                flymat.([scorefields{i},'_dur']) = sum(flymat.([scorefields{i},'_binary']));
                if any(strcmp('fps',fieldnames(info)))
                    [flymat.([scorefields{i},'_binbouts']),flymat.([scorefields{i},'_bindur'])] = ...
                        makeMinuteBins(flymat.([scorefields{i},'_startsm']),...
                        flymat.([scorefields{i},'_binary']),info.fps(1));
                end
            end
        end
        
        % Add info for that fly to the experiment structure
        flymatAll(cnt)=flymat;
    end
end

% Save file
if ~isempty(strfind(expfolder, '/'))
    pathnames = strsplit(expfolder,'/');
elseif ~isempty(strfind(expfolder,'\'))
    pathnames = strsplit(expfolder,'\');
end
experimentname = pathnames(end);
filename = char(strcat('FLYMAT_',experimentname,'.mat'));
save(filename,'flymatAll','-v7.3');

end
