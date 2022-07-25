function modulator(filename)

%Read in JPG image
raw_img = imread(filename, "jpg");

%make it Greyscale
grey_raw_img = im2gray(raw_img);

%Make it 8 bit
processed_img = im2uint8(grey_raw_img);

%Produce APK Data Format

apk_image = []; %Matlab tells me I should preallocate this to make it run faster
for line_num = 1:size(processed_img, 1) %amount of rows in provided image
    %Sync a - pattern of 39 words in the spec
    %pulses going from 11 to 244 decimal lasting 4 words
    sync_a = [];
    for word = 0:38
        if word < 4
            sync_a(end+1) = 11;
        elseif 4 <= word && word <= 30
            mod_val = mod(word, 4);
            if mod_val == 0 || mod_val == 1
                sync_a(end+1) = 244;
            else
                sync_a(end+1) = 11;
            end
        else
            sync_a(end+1) = 11;
        end
    end
    
    %Space A - 47 words of value 0
    space_a = zeros([1 47]);
    
    %Image Data
    img_a = processed_img(line_num, 1:909);
    
    %Telemetry A
    telemetry_a = zeros([1 45]);

    %Sync B
    sync_b = [];
    for word = 0:38;
        if word < 4
            sync_b(end+1) = 11;
        elseif 4 <= word && word <= 37
            mod_val = mod(word - 4, 5);
            if mod_val == 0 || mod_val == 1 || mod_val == 2
                sync_b(end+1) = 244;
            else
                sync_b(end+1) = 11;
            end
        else
            sync_b(end+1) = 11;
        end
    end
    
    %Assembling the line
    the_line = [sync_a space_a img_a telemetry_a sync_b space_a img_a telemetry_a];

    %Append the line to the matrix as a new row
    apk_image(end+1, :) = the_line;
end

%Resample APK data to be 8320 samples 
resampled_apk = zeros(size(apk_image, 1), 8320); 
for line_num = 1:size(apk_image, 1)
    current_line = apk_image(line_num, 1:end);
    
    desired_ratio = 4;
    step_per_sample = 1/desired_ratio;
    
    x = 0:2080-1;
    xq = 0:step_per_sample:2080-step_per_sample; %hopefully should define the new query to be four times upsampling
    
    resampled_line = interp1(x,current_line,xq);
    
    %hacky way to deal with the fact that the last three values were resampled to NaN
    resampled_line(end) = 0;
    resampled_line(end-1) = 0;
    resampled_line(end-2) = 0;
    
    resampled_apk(line_num, :) = resampled_line;
end

%Create a carrier wave of 2.4kHz
A_c = 1;
f_c = 2400;

%Time Vector
seconds_per_sample = 1/(2*8320); 
stopTime = 0.5;
t = (0:seconds_per_sample:stopTime-seconds_per_sample);

%Carrier Wave
carrier = A_c * cos(2 * pi * f_c * t);

result_image = zeros(1, 8320 * size(resampled_apk, 1)); %create a very long vector

%Multiply each line by the carrier
for line_num = 1:size(resampled_apk, 1)
    for col_num = 1:size(resampled_apk, 2)
        modulated_val = resampled_apk(line_num, col_num) * carrier(col_num);
        result_image((line_num - 1) * 8320 + col_num) = modulated_val;
    end
end

%Resample to 16.0Khz
desired_size = size(result_image, 2);

desired_ratio = 16000/16640;
step_per_sample = 1/desired_ratio;

x = 0:(desired_size - 1);
xq = 0:step_per_sample:(desired_size-1);  %it's important that the last value is the original last value

image_16khz = interp1(x,result_image,xq);

%Convert to .wav file
int16_signal = int16(image_16khz);
int16_signal = rescale(int16_signal, -1, 1);

output_filename = filename + ".wav";
audiowrite(output_filename, int16_signal, 16000, 'BitsPerSample', 16)
end
