function [m] = setNtDt(m, timeDesired, freqDesired)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%revise and round the number of time steps so that we can get exactly the
%frequency we want out
%m.dt should already be set
    dtDesired = m.dt;

    ntInit = round(timeDesired/dtDesired);
    dfRes = 1/(ntInit*dtDesired);
    fNum = round(freqDesired/dfRes);
    dfDes = freqDesired/fNum;
    ntRes = round(1/dtDesired/dfDes);
    dtRes = 1/dfDes/ntRes;

    m.dt = dtRes;
    m.nt = ntRes;
end
