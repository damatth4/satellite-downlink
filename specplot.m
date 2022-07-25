% specplot plots the spectrum of input signal x that has a
% a sample period Ts
function specplot(x,Fs)
    Ts = 1/Fs;
    n=length(x);                               % length of the signal x
    t=Ts*(1:n);                                % define a time vector
    f=(ceil(-n/2):ceil(n/2)-1)/(Ts*n);         % frequency vector
    fx=fft(x(1:n));                            % do DFT/FFT
    fxs=fftshift(fx);                          % shift it for plotting
    subplot(2,1,1), plot(t,x)                  % plot the waveform
    xlabel('Time (sec)'); ylabel('Amplitude')  % label the axes
    subplot(2,1,2)
    plot(f,10*log10(abs(fxs))) % plot magnitude spectrum
    xlabel('Freq.'); ylabel('Magnitude')   % label the axes
end