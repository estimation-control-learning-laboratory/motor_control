% SERIAL SETUP
port = "COM5";
baudRate = 9600;
serialObj = serialport(port, baudRate);

configureTerminator(serialObj, "CR/LF");
flush(serialObj); 
pause(2);

% PARAMETERS
duration = 60;
amplitude = 127;
samplingRate = 30;
dt = 1 / samplingRate;

clf;
figure(1);

% Subplot 1: Omega vs Time
subplot(2,1,1);
hPlot = plot(nan, nan, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Omega (rad/s)');
title('Motor Speed (Omega) Over Time');
grid on;

% Subplot 2: PWM vs Time
subplot(2,1,2);
hPWM = plot(nan, nan, 'r', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('PWM Value');
title('PWM Signal Over Time');
grid on;

% FIGURE 2: PWM vs Omega
figure(2);
hStepPlot = plot(nan, nan, 'bo', 'LineWidth', 1.5);
xlabel('PWM Value');
ylabel('Omega (rad/s)');
title('Real-Time Step Response: PWM vs Omega');
grid on;

% USER DATA INIT
startTime = tic;
serialObj.UserData = struct( ...
    "OmegaData", [], ...
    "TimeStamps", [], ...
    "PWMVals", [], ...
    "CurrentPWM", 0, ...
    "PlotHandle", hPlot, ...
    "PWMPlot", hPWM, ...
    "StepPlot", hStepPlot, ...
    "StepPWM", [], ...
    "StepOmega", [], ...
    "StartTime", startTime, ...
    "Duration", duration ...
);

configureCallback(serialObj, "terminator", @(src, event) readMotorOmega(src, event));

timeVals = [];
pwmVals = [];

disp("Running motor...");

while toc(startTime) < duration
    t = toc(startTime);
    pwmVal = round(amplitude * sin((2 * pi / 3) * t));

    % Determine direction
    if pwmVal >= 1
        dir = 1;
    elseif pwmVal <= -1
        dir = -1;
    else
        dir = 0;
    end

    % Updates PWM tracking for step response
    serialObj.UserData.CurrentPWM = pwmVal;

    % Sends PWM command
    setMotor(serialObj, dir, abs(pwmVal));
    pause(dt);

    % Saves for PWM vs Time plot
    timeVals(end+1) = t;
    pwmVals(end+1) = pwmVal;
    set(hPWM, 'XData', timeVals, 'YData', pwmVals);
    drawnow;
end

disp("Closing serial connection...");
setMotor(serialObj, 0, 0);
pause(1);
clear serialObj;

% Function to Send PWM Command
function setMotor(serialObj, dir, pwmVal)
    command = sprintf('%d,%d', dir, pwmVal);
    writeline(serialObj, command);
end

% Callback to Read Incoming Omeg
function readMotorOmega(src, ~)
    data = readline(src);
    parsedData = str2double(data);
    userData = src.UserData;

    if ~isnan(parsedData)
        elapsed = toc(userData.StartTime);
        userData.OmegaData(end + 1) = parsedData;
        userData.TimeStamps(end + 1) = elapsed;
        userData.PWMVals(end + 1) = userData.CurrentPWM;

        % Update Omega vs Time plot
        set(userData.PlotHandle, ...
            'XData', userData.TimeStamps, ...
            'YData', userData.OmegaData);

        % Update Step Response plot
        userData.StepPWM(end + 1) = userData.CurrentPWM;
        userData.StepOmega(end + 1) = parsedData;
        set(userData.StepPlot, ...
            'XData', userData.StepPWM, ...
            'YData', userData.StepOmega);

        drawnow;

        src.UserData = userData;
    end

    if toc(userData.StartTime) >= userData.Duration
        configureCallback(src, "off");
        disp("Omega data collection complete.");
    end
end
