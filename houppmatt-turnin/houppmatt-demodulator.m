% demodulator.m - Accepts a 16KHz / 16 bit .wav file input containing an arbitrary 
% number of lines of APT data and writes an 8-bit grayscale image to a JPEG file. This 
% JPEG image should have dimensions of 1818 x n_lines (presenting the "A" and "B" 
% subimages next to each other) where n_lines is an arbitrary number of lines
% determined by the source .wav file.

function demodulator(filename)
% Demodulates APT formatted .wav signals

% import header and read input file
load("sync_a.mat");
[y,fs] = audioread(filename);

% resampling frequency
frs = 16640; % 16.640kHz
Trs = 1/frs;

% resample with interpolation
l = length(y);
desired_ratio = 16640/16000;
step_per_sample = 1/desired_ratio;
x = 1:l;
xq = 0:step_per_sample:l-step_per_sample;
yrs = interp1(x,y,xq);

yrs = rmmissing(yrs);% get rid of NaNs

% carrier for demodulation
fc = 2400; % 2.4kHz carrier freq
samples = length(yrs);
Ac = 1; % Carrier wave magnitude
t = 0:Trs:samples/frs; % 0.5 seconds
ct = Ac * cos(2*pi*fc*t); % c(t) => carrier wave

% 7th order Butterworth LPF
filterOrder = 7;
fcutoff = 3500;
[b,a]=butter(filterOrder,fcutoff/(fs/2));


% downshift signal
yrs_mult_ct = yrs .* ct(2:end);
% filter
y_dm_lpf = filtfilt(b,a,yrs_mult_ct);

% upsample header -> 4x
sync_a_sample_count = length(sync_a);
desired_ratio = 4;
step_per_sample = 1/desired_ratio;
xsync = 1:sync_a_sample_count;
xqsync = 0:step_per_sample:sync_a_sample_count-step_per_sample;
sync_a_upsampled_4x = interp1(xsync,sync_a,xqsync);

% normalize filtered and shifted input signal
y_norm = y_dm_lpf / max(abs(y_dm_lpf));

% ==== Synchronization ====
% cross correlate signal and header
[z,lag_z] = xcorr(sync_a_upsampled_4x, y_norm(1:8400));
z = z/max(z);

[Mz,Iz] = max(z); % calculate index of the correlation peak
tz = lag_z(Iz); % find offset value
if (tz < 0)
    tz_abs = -tz;
else 
    tz_abs = tz;
end
zc = circshift(y_norm,tz_abs); % align signal
% =========================

% ==== Reconstruct Data ====
samples_per_line_2 = 8320; % samples/line for upsampled signal

% iterate through signal to recreate image array
total_samples = length(zc);
h = int16(total_samples/samples_per_line_2);
apt_array = zeros(h,samples_per_line_2);

row = 1;
for i = 1:samples_per_line_2:total_samples
        if i < total_samples-samples_per_line_2
            current_slice = zc(i:i+samples_per_line_2-1);
            current_slice_rescaled = (rescale(current_slice,11,244));
            apt_array(row, :) = int16(current_slice_rescaled);
            row = row+1;
        else 
            apt_array(row,1:length(zc(i:end))) = zc(i:end);
        end
end

word = 4;
 
imagesc(apt_array(:,87*word:996*word));
colormap("gray");

% write to file
 map =  colormap("gray");
 filename_out = filename + ".jpg";
 image = apt_array(:,87*word:996*word);
 imwrite(image, map, filename_out)
% ==========================

end % end demod function