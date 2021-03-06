%ScanConvert - Converts from tissue coordinates to pixel coordinates.
%
% Syntax:  [frame, WindowTissueX, WindowTissueY] = ScanConvert(RF,...
%    StartLineX, StartLineY, StartLineAngle, StartDepth, StopLineX, ...
%    StopLineY, StopLineAngle, StopDepth, WindowTissueXMin, ...
%    WindowTissueYMin, WindowTissueXMax, WindowTissueYMax)
%
% Inputs:
%   RF                : RF data (envelope) [row = axial direction,
%                                         col = lateral direction]
%   WindowTissueXMin  : Tissue area of the window in meters
%   WindowTissueYMin  :    Xmin ----- Ymin ------- Xmax
%   WindowTissueXMax  :      -                       -
%   WindowTissueYMax  :      -------- Ymax(positive)--
%                   
%                     : Scan area description for B-mode
%   StartLineX        : X-coordinate of the start line origin in m.
%   StartLineY        : Y-coordinate of the start line origin in m.
%   StartLineAngle    : Angle of the start line in radians.
%   StartDepth        : Start depth of the scanning area in m.
%   StopLineX         : X-coordinate of the stop line origin in m.
%   StopLineY         : Y-coordinate of the stop line origin in m.
%   StopLineAngle     : Angle of the stop line in radians.
%   StopDepth         : Stop depth of the scanning area in m.
% 
% Outputs:
%   frame             : Scanconverted image defined in pixel coordinates
%                       range is [0-1]
%   WindowTissueX     : X-coordinates for the scanconverted image in m.
%   WindowTissueY     : Y-coordinates for the scanconverted image in m.
%
% Example: 
%   [frame, WindowTissueX, WindowTissueY] = ScanConvert(RF,...
%    StartLineX, StartLineY, StartLineAngle, StartDepth, StopLineX, ...
%    StopLineY, StopLineAngle, StopDepth, WindowTissueXMin, ...
%    WindowTissueYMin, WindowTissueXMax, WindowTissueYMax)
%
% Version 1:
% * Linear scanconvert is working 100%
% * Sector scanconvert needs testing
%
% Other m-files required: make_tables, make_interpolation
% Subfunctions: none
% MAT-files required: none
%
% See also: interp2
%
% Author: Martin Christian Hemmsen
% Danish Technical University and BK Medical
% email: mah@elektro.dtu.dk
% Website: http://server.elektro.dtu.dk/personal/mah/
% Feb 2009; Last revision: 9-Feb-2009
function [frame, WindowTissueX , WindowTissueY] = ScanConvert(RF,StartLineX, StartLineY,...
    StartLineAngle, StartDepth, StopLineX, StopLineY, StopLineAngle,...
    StopDepth, WindowTissueXMin, WindowTissueYMin, WindowTissueXMax,...
    WindowTissueYMax,varargin)

if(StopLineAngle == StartLineAngle)
    type = 'linear';
else
    type = 'sector';
end
switch(nargin)
    case 13
        plott = 0;
    case 14
        plott = varargin{1};
    otherwise
        return;
end

switch(type)
    case 'linear'
        ScreenPixelsPerInch = get(0,'ScreenPixelsPerInch');
        ScreenPixelsPerCentimeter = ScreenPixelsPerInch/2.54;

        Tissue_Width = WindowTissueXMax - WindowTissueXMin; % m
        Tissue_Height = WindowTissueYMax - WindowTissueYMin;  % m
        
        zoom = 2;

        Width = round(Tissue_Width*100*ScreenPixelsPerCentimeter*zoom);
        Height = round(Tissue_Height*100*ScreenPixelsPerCentimeter*zoom);
      
        WindowTissueX = repmat([WindowTissueXMin:(...
            WindowTissueXMax-WindowTissueXMin)/...
            (Width-1):WindowTissueXMax],Height,1);
        WindowTissueY = repmat([WindowTissueYMin:(...
            WindowTissueYMax-WindowTissueYMin)/...
            (Height-1):WindowTissueYMax]',1,Width);

        
        ScanAreaX = repmat([StartLineX:(StopLineX-...
           StartLineX )/(size(RF,2)-1):StopLineX],size(RF,1),1);
        ScanAreaY = repmat([StartDepth:...
            (StopDepth-StartDepth)/(size(RF,1)-1):StopDepth]',1,size(RF,2));
        
        if(plott)
            figure
            p1 = plot(ScanAreaX,ScanAreaY,'bx','MarkerSize',4);
            hold on
            p2 = plot(WindowTissueX,WindowTissueY,'ro','MarkerSize',4);
            hold off
            legend([p1(1), p2(1)],'Scan points','Pixel points');
        end
        RF(isnan(RF)) = 0;
        frame = interp2(ScanAreaX,ScanAreaY,...
                 RF,WindowTissueX,WindowTissueY,'spline');  
           
        
        frame(WindowTissueX > ScanAreaX(1,1)) = NaN;
        frame(WindowTissueX < ScanAreaX(end,end)) = NaN;

        frame(WindowTissueY < ScanAreaY(1,1)) = NaN;
        frame(WindowTissueY > ScanAreaY(end,end)) = NaN;
               
        WindowTissueX = WindowTissueX(1,:);
        WindowTissueY = WindowTissueY(:,1);
        
%         frame(frame<min(min(RF)))=min(min(RF));
%         frame(frame>max(max(RF)))=max(max(RF));
            
        % extract data from frame that we want to show
%         index_x = WindowTissueX >= useCaseParams.scanparams(1).windowtissueq.x_tismin & ...
%                     WindowTissueX <= useCaseParams.scanparams(1).windowtissueq.x_tismax;
%         index_y = WindowTissueY >= useCaseParams.scanparams(1).windowtissueq.y_tismin & ...
%                     WindowTissueY <= useCaseParams.scanparams(1).windowtissueq.y_tismax;
                
        index_x = WindowTissueX >= WindowTissueXMin & ...
                    WindowTissueX <= WindowTissueXMax;
        index_y = WindowTissueY >= WindowTissueYMin & ...
                    WindowTissueY <= WindowTissueYMax;

        WindowTissueX = WindowTissueX(index_x);
        WindowTissueY = WindowTissueY(index_y);
        
        frame = round(frame(index_y,index_x));
%         frame(frame < 0) = 0;
%         frame(frame > 255) = 255;
%         WindowTissueX = WindowTissueX(index_x);
%         WindowTissueY = WindowTissueY(index_y);
        frame(isnan(frame)) = 0;
    case 'sector'
        disp('Sector Scan is used')
        
        ScreenPixelsPerInch = get(0,'ScreenPixelsPerInch');
        ScreenPixelsPerCentimeter = ScreenPixelsPerInch/2.54;

        Tissue_Width = WindowTissueXMax - WindowTissueXMin; % m
        Tissue_Height = WindowTissueYMax - WindowTissueYMin;  % m

%         scaling = 1.4;
        scaling = 1;
        Width = round(Tissue_Width*100*ScreenPixelsPerCentimeter*scaling);
        Height = round(Tissue_Height*100*ScreenPixelsPerCentimeter*scaling);
                   
        % convert to uint32
        RF = uint32(RF); 
 
        N_samples = size(RF,1);                      % nr. of samples in each line
        N_lines = size(RF,2);                        % nr. of lines
        theta_start = -StartLineAngle+pi/2;          % start angle 
        delta_theta = (StartLineAngle-StopLineAngle)/(N_lines-1);% angle between individual lines
        delta_r = (StopDepth-StartDepth)/(N_samples-1);  % sampling interval for data in meters
        Nz = Height;
        Nx = Width;

        offset = -(tan(pi-StopLineAngle)*StopLineX+StopLineY);

        StartDepth = offset+StartDepth;   
        
        img_start_depth = WindowTissueYMin+offset;
        if(WindowTissueYMax-WindowTissueYMin > WindowTissueXMax-WindowTissueXMin)
            image_size = WindowTissueYMax-WindowTissueYMin;
            Nx = Nz;
        else
            image_size = WindowTissueXMax-WindowTissueXMin;
            Nz = Nx;
        end
%         image_size = max(WindowTissueYMax-WindowTissueYMin,WindowTissueXMax-WindowTissueXMin);
%%       
        Nx = 1024*2;
        Nz = 1024*2;
        Nx = 800;
        Nz = 800;
        make_tables(img_start_depth,... % start_depth    - Depth for start of image in meters
                    image_size,...      % image_size     - Size of image in meters
                    StartDepth, ...     % start_of_data  - Depth for start of data in meters
                    delta_r, ...        % delta_r        - Sampling interval for data in meters
                    N_samples,...       % N_samples      - Number of samples in one envelope line
                    theta_start, ...    % theta_start    - Angle for first line in image
                    delta_theta, ...    % delta_theta    - Angle between individual lines
                    N_lines,...         % N_lines        - Number of acquired lines
                    1, ...              % scaling        - Scaling factor from envelope to image
                    Nz, ...             % Nz             - Size of image in pixels
                    Nx);                % Nx             - Size of image in pixels

        frame = double(make_interpolation(RF));
        
        %%
%         fprintf('max frame: %d\n',max(frame(:)))
        WindowTissueX = linspace(0,image_size,Nx);
        WindowTissueX = fliplr(WindowTissueX-WindowTissueX(end)/2);
        
        WindowTissueY = linspace(img_start_depth-offset,image_size+img_start_depth-offset,Nz);

        % extract data from frame that we want to show
        index_x = WindowTissueX >= WindowTissueXMin & ...
                    WindowTissueX <= WindowTissueXMax;
        index_y = WindowTissueY >= WindowTissueYMin & ...
                    WindowTissueY <= WindowTissueYMax;

        WindowTissueX = WindowTissueX(index_x);
        WindowTissueY = WindowTissueY(index_y);
        
        frame = frame(index_y,index_x);
    case 'otherwise'
        disp('The Scan Converter is not implemented to handle this type of scan!')
end

% Please send suggestions for improvement to Martin Christian Hemmsen at 
% this email address: mah@elektro.dtu.dk
% Your contribution towards improving this code will be acknowledged in
% the "Changes" section.