function [ionoData] = loadIONEX(filePath)
%% generate IONEX data structure
ionoData = struct('headerData',[],'mapData',[]);

%% open file
waitBar = waitbar(0,'Open IONEX file...','Name','Reading IONEX file');
fid = fopen(filePath);

%% read header
waitbar(0,waitBar,'Read header...');
headerData = struct('fileVer',[],'epochOfFirstMap',[],'epochOfLastMap',[],'interval',[],'mappingFunction',[], ...
    'observationUsed',[],'elevationCutOff',[],'baseRadius',[],'mapDimension',[], ... 
    'HGT1',[],'HGT2',[],'DHGT',[],'LAT1',[],'LAT2',[],'DLAT',[],'LON1',[],'LON2',[],'DLON',[],'exponent',[]);
while true
    line = fgetl(fid);
    if contains(line,'IONEX VERSION / TYPE')
        
        headerData.fileVer = real(str2doubleq(line(1:9)));
        
    elseif contains(line,'EPOCH OF FIRST MAP')
        
        epochOfFirstMap.year = real(str2doubleq(line(1:6)));
        epochOfFirstMap.month = real(str2doubleq(line(7:12)));
        epochOfFirstMap.day = real(str2doubleq(line(13:18)));
        epochOfFirstMap.hour = real(str2doubleq(line(19:24)));
        epochOfFirstMap.min = real(str2doubleq(line(25:30)));
        epochOfFirstMap.sec = real(str2doubleq(line(31:36)));
        headerData.epochOfFirstMap = epochOfFirstMap;
        
    elseif contains(line,'EPOCH OF LAST MAP')
        
        epochOfLastMap.year = real(str2doubleq(line(1:6)));
        epochOfLastMap.month = real(str2doubleq(line(7:12)));
        epochOfLastMap.day = real(str2doubleq(line(13:18)));
        epochOfLastMap.hour = real(str2doubleq(line(19:24)));
        epochOfLastMap.min = real(str2doubleq(line(25:30)));
        epochOfLastMap.sec = real(str2doubleq(line(31:36)));
        headerData.epochOfLastMap = epochOfLastMap;
        
    elseif contains(line,'INTERVAL')
        
        headerData.interval = real(str2doubleq(line(1:6)));
        
    elseif contains(line,'MAPPING FUNCTION')
        
        headerData.mappingFunction = line(3:6);
        
    elseif contains(line,'OBSERVABLES USED')
        
        headerData.observationUsed = line(1:60);
        
    elseif contains(line,'ELEVATION CUTOFF')
        
        headerData.elevationCutOff = real(str2doubleq(line(1:9)));
        
    elseif contains(line,'BASE RADIUS')
        
        headerData.baseRadius = real(str2doubleq(line(1:9)));
        
    elseif contains(line,'MAP DIMENSION')
        
        headerData.mapDimension = real(str2doubleq(line(1:6)));
        
    elseif contains(line,'HGT1 / HGT2 / DHGT')
        
        headerData.HGT1 = real(str2doubleq(line(3:8)));
        headerData.HGT2 = real(str2doubleq(line(9:14)));
        headerData.DHGT = real(str2doubleq(line(15:20)));
        
    elseif contains(line,'LAT1 / LAT2 / DLAT')
        
        headerData.LAT1 = real(str2doubleq(line(3:8)));
        headerData.LAT2 = real(str2doubleq(line(9:14)));
        headerData.DLAT = real(str2doubleq(line(15:20)));
        
    elseif contains(line,'LON1 / LON2 / DLON')
        
        headerData.LON1 = real(str2doubleq(line(3:8)));
        headerData.LON2 = real(str2doubleq(line(9:14)));
        headerData.DLON = real(str2doubleq(line(15:20)));
        
    elseif contains(line,'EXPONENT')
        
        headerData.exponent = real(str2doubleq(line(1:6)));
        
    elseif contains(line,'END OF HEADER')
        
        break;
        
    end
end
ionoData.headerData = headerData;

%% read map data
waitbar(0,waitBar,'Read map data...');
mapData = struct('time',[],'TECMAP',[],'RMSMAP',[],'HGTMAP',[]);
if headerData.interval ~= 0
    timeDiff = (datenum(epochOfLastMap.year,epochOfLastMap.month,epochOfLastMap.day) - datenum(epochOfFirstMap.year,epochOfFirstMap.month,epochOfFirstMap.day)) * 86400 ...
        + (epochOfLastMap.hour - epochOfFirstMap.hour) * 3600 + (epochOfLastMap.min - epochOfFirstMap.min) * 60 + (epochOfLastMap.sec - epochOfFirstMap.sec);
    nEpoch = timeDiff / headerData.interval;
    mapData = repmat(mapData,1,nEpoch);
end

if headerData.mapDimension == 2
    nLat = (headerData.LAT2 - headerData.LAT1) / headerData.DLAT;
    nLon = (headerData.LON2 - headerData.LON1) / headerData.DLON;
    dataNan = nan(nLat,nLon);
elseif headerData.mapDimension == 3
    nLat = (headerData.LAT2 - headerData.LAT1) / headerData.DLAT;
    nLon = (headerData.LON2 - headerData.LON1) / headerData.DLON;
    nHgt = (headerData.HGT2 - headerData.HGT1) / headerData.DHGT;
    dataNan = nan(nLat,nLon,nHgt);
end

while true
    line = fgetl(fid);
    if contains(line,'START OF TEC MAP') || contains(line,'START OF RMS MAP') || contains(line,'START OF HEIGHT MAP')

        data = dataNan;
        if isfield(headerData,'exponent')
            exponent = headerData.exponent;
        end
        epochIndex = real(str2doubleq(line(1:6)));

    elseif contains(line,'EPOCH OF CURRENT MAP')
        
        time.year = real(str2doubleq(line(1:6)));
        time.month = real(str2doubleq(line(7:12)));
        time.day = real(str2doubleq(line(13:18)));
        time.hour = real(str2doubleq(line(19:24)));
        time.min = real(str2doubleq(line(25:30)));
        time.sec = real(str2doubleq(line(31:36)));
        mapData(epochIndex).time = time;
        
    elseif contains(line,'EXPONENT')
        
        exponent = real(str2doubleq(line(1:6)));
        
    elseif contains(line,'LAT/LON1/LON2/DLON/H')
        
        lat = real(str2doubleq(line(3:8)));
        lon1 = real(str2doubleq(line(9:14)));
        lon2 = real(str2doubleq(line(15:20)));
        dlon = real(str2doubleq(line(21:26)));
        hgt = real(str2doubleq(line(27:32)));
        
        for lon = lon1:dlon:lon2
            latIndex = (lat - headerData.LAT1) / headerData.DLAT + 1;
            lonIndex = (lon - lon1) / dlon + 1;
            hgtIndex = (hgt - headerData.HGT1) / headerData.DHGT + 1;
            
            index = mod(lonIndex - 1,16);
            if index == 0
                line = fgetl(fid);
            end
            
            if headerData.mapDimension == 2
                data(latIndex,lonIndex) = 10^exponent * real(str2doubleq(line(5*index+1:5*(index+1))));
            elseif headerData.mapDimension == 3
                data(latIndex,lonIndex,hgtIndex) = 10^exponent * real(str2doubleq(line(5*index+1:5*(index+1))));
            end
            
        end
        
    elseif contains(line,'END OF TEC MAP')
        
        if epochIndex == real(str2doubleq(line(1:6)))
            mapData(epochIndex).TECMAP = data;
            if headerData.interval ~= 0
                waitbar(epochIndex/nEpoch,waitBar,sprintf('Read TEC MAP:%d',epochIndex));
            else
                waitbar(epochIndex/10000,waitBar,sprintf('Read TEC MAP:%d',epochIndex));
            end
        else
            error 'TEC MAP epochIndex error'
        end
        
    elseif contains(line,'END OF RMS MAP')
        
        if epochIndex == real(str2doubleq(line(1:6)))
            mapData(epochIndex).RMSMAP = data;
            if headerData.interval ~= 0
                waitbar(epochIndex/nEpoch,waitBar,sprintf('Read RMS MAP:%d',epochIndex));
            else
                waitbar(epochIndex/10000,waitBar,sprintf('Read RMS MAP:%d',epochIndex));
            end
        else
            error 'RMS MAP epochIndex error'
        end
        
    elseif contains(line,'END OF HEIGHT MAP')
        
        if epochIndex == real(str2doubleq(line(1:6)))
            mapData(epochIndex).HGTMAP = data;
            if headerData.interval ~= 0
                waitbar(epochIndex/nEpoch,waitBar,sprintf('Read HEIGHT MAP:%d',epochIndex));
            else
                waitbar(epochIndex/10000,waitBar,sprintf('Read HEIGHT MAP:%d',epochIndex));
            end
        else
            error 'HEIGHT MAP epochIndex error'
        end
        
    elseif contains(line,'END OF FILE')
        
        break;
        
    end
        
end

ionoData.mapData = mapData;
close(waitBar);
fclose(fid);
end