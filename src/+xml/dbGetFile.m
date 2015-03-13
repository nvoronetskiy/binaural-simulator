function filename = dbGetFile(filename, bVerbose)
% search for file locally and in database
%
% USAGE
%   filename = dbGetFile(filename, bVerbose)
%
% INPUT PARAMETERS
%   filename - filename
%   bVerbose - optional boolean verbosity parameter. Default: 0.
%
% OUTPUT PARAMETERS
%   filename - filename of file found locally or in database
%
% DETAILS
%   search for file specified by filename relative to current directory.
%   Filenames starting with '/' will interpreted as absolute paths. If the file
%   is not found, searching will be extended to the local copy of the
%   Two!Ears database (database path defined via xml.dbPath()). Again,
%   searching will be extended to the remote database (defined via
%   xml.dbURL). If the download was successfull, the file will be cached in
%   'src/tmp'. The cache can be cleared via xml.dbClearTmp()
%
% See also: xml.dbPath xml.dbURL xml.dbClearTmp

import xml.*;

narginchk(1,2);
isargchar(filename);
if nargin < 2
    bVerbose = 0;
end

try
    % try relative path
    isargfile(fullfile(pwd,filename));
    if bVerbose
        fprintf(strcat('INFO: relative local file (%s) found, will not ', ...
            'search in database\n'), filename);
    end
    filename = fullfile(pwd,filename);
    return;
catch
    try
        % try absolute path
        isargfile(filename);
        if bVerbose
            fprintf(strcat('INFO: absolute local file (%s) found, will not ', ...
                'search in database\n'), filename);
        end
        return;
    catch
        try
            % try local database
            isargfile(fullfile(dbPath(),filename));
            if bVerbose
                fprintf('INFO: file (%s) found in local database\n', filename);
            end
            filename = fullfile(dbPath(),filename);
            return;
        catch
            if bVerbose
                fprintf(strcat('INFO: file (%s) not found in local database ', ...
                    '(dbPath=%s), trying remote database\n'), filename, dbPath());
            end
            % try cache of remote database
            try
                tmppath = xml.dbTmp();
                isargfile(fullfile(tmppath,filename));
                if bVerbose
                    fprintf('INFO: file (%s) found in cache of remote database\n', ...
                        filename);
                end
                filename = fullfile(tmppath,filename);
                return;
            catch
                % try download from remote database
                filename = dbDownloadFile(filename);
            end
        end
    end
end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
