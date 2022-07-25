%{
Impairment Generator Specification
Accepts a .wav file input along with a signal-to-noise power ratio in dB 
and writes a .wav file output including AWGN calculated to yield 
the requested signal-to-noise power ratio. 

The impairment generator shall add AWGN to the signal in the WAV file 
in such a way that the specified signal to noise ratio in dBis achieved

For example, let us assume that a signal to impairment ratio of +10dB is to be generated.
This means that signal power shall be 10X greater than noise power, 
averaged over the entire input file. 

Start by finding the average signal power in the input signal over the entire input file. 

Add AWGN on a per-sample basis with an appropriate variance chosen 
to yield the required noise power ratio. 

Now re-scale the resulting samples to the appropriate range for the audiowrite()function

%}

%Take in Audio Data

function impairment(filename, SNR)
[audio_input,fs] = audioread(filename + ".wav");

%Take in SNR


%Start by finding the average signal power in the input signal over the entire input file. 

%Assumption: Average power formula is as follows 
% Sum of (signal value ^2) for all data points, divided by total amount of
% points

avg_power = (1 / size(audio_input,1)) * sum(audio_input .* audio_input); %Squaring each value by multiplying it with itself

%%Add AWGN on a per-sample basis with an appropriate variance chosen 
%to yield the required noise power ratio. 

variance = avg_power / (10 ^ (SNR / 10));

%Normal distribution and gaussian distribution are the same thing
%We can create them by producing an array of standard gaussian variables, multiplied by the standard deviation
audio_size = size(audio_input, 1);
gaussian_vals = sqrt(variance).*randn(audio_size,1);

%Add it to each value
noisy_audio = gaussian_vals + audio_input;

%Now re-scale the resulting samples to the appropriate range for the audiowrite()function
rescaled_noisy_audio = rescale(noisy_audio, -1, 1);

%Write Audio Output

output_filename = "houppmatt-" + "impair" + int2str(SNR) + "dB.wav";
audiowrite(output_filename, rescaled_noisy_audio, 16000, 'BitsPerSample', 16)
end
