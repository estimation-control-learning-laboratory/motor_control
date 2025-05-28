port = "COM5";
baudRate = 9600;
serialObj = serialport(port, baudRate);

configureTerminator(serialObj, "CR/LF");
flush(serialObj); 
pause(2);
pwmStart = -250;
pwmEnd = 250;
pwmStep = 10;
holdTime = 5; % seconds per step
pwmSequence = pwmStart:pwmStep:pwmEnd;
duration = length(pwmSequence) * holdTime; % total test duration
samplingRate = 30;
dt = 1 / samplingRate;

% Omega and PWM vs Time
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

% PWM vs Omega
figure(2);
hStepPlot = plot(nan, nan, 'bo', 'LineWidth', 1.5);
xlabel('PWM Value');
ylabel('Omega (rad/s)');
title('PWM vs Omega');
grid on;


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

for i = 1:length(pwmSequence)
    pwmVal = pwmSequence(i);
    dir = sign(pwmVal);
    absPWM = abs(pwmVal);
    
    stepStart = tic;
    while toc(stepStart) < holdTime
        t = toc(startTime);
        

        serialObj.UserData.CurrentPWM = pwmVal;


        setMotor(serialObj, dir, absPWM);
        pause(dt);


        timeVals(end+1) = t;
        pwmVals(end+1) = pwmVal;
        set(hPWM, 'XData', timeVals, 'YData', pwmVals);
        drawnow;
    end
end

disp("Closing serial connection...");
setMotor(serialObj, 0, 0);
pause(1);
clear serialObj;


function setMotor(serialObj, dir, pwmVal)
    command = sprintf('%d,%d', dir, pwmVal);
    writeline(serialObj, command);
end

function readMotorOmega(src, ~)
    data = readline(src);
    parsedData = -str2double(data);  % Invert Omega
    userData = src.UserData;

    if ~isnan(parsedData)
        elapsed = toc(userData.StartTime);
        userData.OmegaData(end + 1) = parsedData;
        userData.TimeStamps(end + 1) = elapsed;
        userData.PWMVals(end + 1) = userData.CurrentPWM;

        set(userData.PlotHandle, ...
            'XData', userData.TimeStamps, ...
            'YData', userData.OmegaData);


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
