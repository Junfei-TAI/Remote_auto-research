function output = tbgeneration(frequency, cycles, timedelay, timestep, endtime,phase,filename)
% Frequency in kHz
windowlength = cycles/(frequency*1e3);
% timestep=(1/(frequency*1e3*timestepno)); [This option has been commented
% by me becasue I discovered that the time incrementation must be set
% equivalent to the calculated stable time increment.]
% Initialize output vector
output(:,1) = [0:timestep:endtime]';
output(:,2) = 0;

% Generate toneburst signal
signal(:,1) = ...
    0.5 * (1 - cos(2*pi*frequency*1e3/cycles*output(1:round(windowlength/timestep+1),1)))...
    .*sin((2*pi*frequency*1e3*output(1:round(windowlength/timestep+1),1))+phase);

% Adjust delay
output(round(timedelay/timestep+1):round((timedelay+windowlength)/timestep+1), 2) = signal(:,1);
f_domain=fft(output(:,2),1e-3/timestep);

% end of file

figure;set(gcf,'color','w');
subplot(1,2,1);plot(output(:,1),output(:,2),'b-');xlabel('Time(s)');
subplot(1,2,2);plot(abs(f_domain(2:frequency*5)));xlabel('Frequency(kHz)');


fid = fopen([filename,'.dat'],'w');
% k=1;
% while k < length(output(:,1))-3
%     fprintf(fid,'%12.11f,%12.11f,%12.11f,%12.11f,%12.11f,%12.11f,%12.11f,%12.11f\n',...
%         output(k,1),output(k,2),output(k+1,1),output(k+1,2),output(k+2,1),output(k+2,2),output(k+3,1),output(k+3,2));
%     k=k+4;  
% end
% for k2=k:length(output(:,1))
%     fprintf(fid,'%12.11f,%12.11f', output(k2,1),output(k2,2));
%     if k2 < length(output(:,1)) 
%         fprintf(fid, ',');
%     end
% end   
fprintf(fid,'%12.11f,%12.11f\n',output');
fclose(fid);
% output=1;
