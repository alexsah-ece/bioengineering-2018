%% Initialization
files = ['../dataset/Data_Eval_E_1.mat'; '../dataset/Data_Eval_E_2.mat'; '../dataset/Data_Eval_E_3.mat'; '../dataset/Data_Eval_E_4.mat'];

allData=zeros(4,1440000);
spike_Times = cell(4,1);
spike_Class = cell(4,1);

for i=1:1:4
    load(files(i,:));
    allData(i,:) = data;
    spike_Times{i} = spikeTimes;
    spike_Class{i} = spikeClass;
end
%change name for more intuition & clear temp variables
spikeTimes = spike_Times;   
spikeClass = spike_Class;
clear spike_Times spike_Class;

k=@(sigma)(1.861248757651653+0.250156158913673./sigma-0.008006893531367./(sigma.*sigma)-2.410871628915119e-05/(sigma.*sigma.*sigma));
disp("Q2.1")
%% Q2.1
sigmas=zeros(4,1);
measuredNumSpikes=zeros(4,1);
T = zeros(4,1);
%spikeTimesEst {estimation of when a spike did appear} initialization
spikeTimesEst = cell(4,1);
for i=1:1:4
    count=0;
    sigmas(i)=median(abs(allData(i,:)))/0.6745;
    T(i)=k(sigmas(i))*sigmas(i);
    previousMeasuredSpike=0;
    for m=1:1:1440000
       if ((allData(i,m))>T(i) && previousMeasuredSpike==0)
           measuredNumSpikes(i)=measuredNumSpikes(i)+1;
           count=count+1;
           spikeTimesEst{i}(count)=m;
           previousMeasuredSpike=m;
       elseif (previousMeasuredSpike~=0 && (allData(i,m))<T(i))
           previousMeasuredSpike=0;
       end
    end
end

disp("Q2.2")
%% Q2.2
%spikeEst {4-cell matrix, containing arrays that display the waveforms of all the measured spikes}
spikesEst = cell(4,1);
for j=1:1:4
    spikesEst{j} = zeros(length(spikeTimesEst{j}),64);
    centers=zeros(length(spikeTimesEst{j}),1);
    for i=1:1:length(spikeTimesEst{j})
       k=spikeTimesEst{j}(i);
       [minimum, minIndex] = min(allData(j,k-31:k+32));
       [maximum, maxIndex] = max(allData(j,k-31:k+32));
       if (minIndex < maxIndex)
           centers(i) = minIndex + k-32 -1;
       else
           centers(i) = maxIndex + k-32 -1;
       end
       spikesEst{j}(i,:)=allData(j, centers(i)-31:centers(i)+32);
       %spikeTimesNewEst_1(i) = centers(i);
    end
    figure()
    plot(1:1:64, spikesEst{j}(:,:));
end

disp("Q2.3")
%% Q2.3
spikesCounted = cell(4,1);

for m=1:1:4
    %initialize spikesCounted {spikes correlated to the real ones}
    N = min(length(spikeTimes{m}), length(spikeTimesEst{m}));
    spikesCounted{m}=zeros(N,1);
    %for every real spike, find one of the measured ones to correlate to
    for i=1:1:length(spikeTimes{m})
        if (i <= N)
            [minimum, spikesCounted{m}(i)] = min(abs(spikeTimesEst{m}(:)-spikeTimes{m}(i)));
        end
    end
end

disp("Q2.4")
%% Q2.4
attr = cell(4,1);
for i=1:1:4
    %let's begin with two attributes
    attr{i} = zeros(length(spikesEst{i}(:,64)),2);
    for j=1:1:length(spikesEst{i}(:,64))
        %attr{1} peak to peak amplitude
        attr{i}(j,1) = peak2peak(spikesEst{i}(j,:));
        %attr{2} zero crossing frequency
        count = 0;
        for k=1:1:63
            if (spikesEst{i}(j,k)*spikesEst{i}(j,k+1) < 0)
                attr{i}(j,2) = attr{i}(j,2) + 1;
            end
             if (spikesEst{i}(j,k) > T(i))
                count = count + 1;
            end
            
        end
        %atrr{3} median frequency
        attr{i}(j,3) = medfreq(spikesEst{i}(j,:));
        %attr{4} power of the signal
        attr{i}(j,4) = sum(spikesEst{i}(j,:).^2);
        %attr{5} mean of the signal
        attr{i}(j,5) = mean(spikesEst{i}(j,:));
        %attr{6} variance of the signal
        attr{i}(j,6) = var(spikesEst{i}(j,:));
        %attr{7} maximum diff between two consecutive values
        attr{i}(j,7) = max(diff(spikesEst{i}(j,:)));
        %attr{8} trapezoid integral of signal
        attr{i}(j,8) = trapz(spikesEst{i}(j,:));
        %attr{9} fft max appearing frequency
        [value,index] = max(abs(fft(spikesEst{i}(j,:))));
        attr{i}(j,9) = index;
        %attr{10} rms value
        attr{i}(j,10) = rms(spikesEst{i}(j,:));
        %attr{10} kurtosis
        attr{i}(j,11) = kurtosis(spikesEst{i}(j,:));
        %attr{12} distance between min and max
        [value, minIndex] = min(spikesEst{i}(j,:));
        [value, maxIndex] = max(spikesEst{i}(j,:));
        attr{i}(j,12) = maxIndex - minIndex;
        %attr{13} number of values above threshold
        attr{i}(j,13) = count;
        %attr{14} skewness
        attr{i}(j,14) = skewness(spikesEst{i}(j,:));
    end
    data = mapminmax(attr{i}(spikesCounted{i}(:),:), 0, 1);
    neuron_1 = data((spikeClass{i}(1:length(data)) == 1),:);
    [coef, neuron_1_pca, lat] = pca(neuron_1);
    neuron_2 = data((spikeClass{i}(1:length(data)) == 2),:);
    [coef, neuron_2_pca, lat] = pca(neuron_2);
    neuron_3 = data((spikeClass{i}(1:length(data)) == 3),:);
    [coef, neuron_3_pca, lat] = pca(neuron_3);
    %2D plot - selected power and kurtosis as attributes
    figure()
    plot(neuron_1(:,11), neuron_1(:,4),'.r',neuron_2(:,11), neuron_2(:,4), '.g',neuron_3(:,11), neuron_3(:,4), '.b');
    title('2D plot - selected power and kurtosis as attributes')
    legend({'neuron 1','neuron 2', 'neuron 3'},'Location','northeast')
    %2D plot - selected first 2 principal components
    figure()
    plot(neuron_1_pca(:,1), neuron_1_pca(:,2),'.r',neuron_2_pca(:,1), neuron_2_pca(:,2), '.g',neuron_3_pca(:,1), neuron_3_pca(:,2), '.b');
    title('2D plot - selected power and kurtosis as attributes')
    legend({'neuron 1','neuron 2', 'neuron 3'},'Location','northeast')
    %2D plot - selected last 2 principal components
    figure()
    plot(neuron_1_pca(:,13), neuron_1_pca(:,14),'.r',neuron_2_pca(:,13), neuron_2_pca(:,14), '.g',neuron_3_pca(:,13), neuron_3_pca(:,14), '.b');
    title('2D plot - selected last 2 principal components')
    legend({'neuron 1','neuron 2', 'neuron 3'},'Location','northeast')
    %3D plot - selected first 3 principal components
    figure()
    scatter3(neuron_1_pca(:,1), neuron_1_pca(:,2), neuron_1_pca(:,3),'.r')
    hold on
    scatter3(neuron_2_pca(:,1), neuron_2_pca(:,2), neuron_2_pca(:,3),'.g')
    hold on
    scatter3(neuron_3_pca(:,1), neuron_3_pca(:,2), neuron_3_pca(:,3),'.b')
    title('3D plot - selected first 3 principal components')
    legend({'neuron 1','neuron 2', 'neuron 3'},'Location','northeast')
end

%% Q2.5
acc = zeros(4,1);
data = cell(4,1);
for i=1:1:4
   data{i} = attr{i}(spikesCounted{i}(:),:);
   [coef, data{i}, lat] = pca(data{i});
   data{i} = data{i}(:,1:10);
   spikeClass{i} = spikeClass{i}(1:length(data{i}));
   acc(i) = MyClassify(data{i},spikeClass{i}(:));
end

disp(acc);