% Train the weights for weighted Hamming distance

if ismac || ispc; error('Currently only supports Linux.'); end
load('../dat/meshes.mat');
load('../dat/features.mat');
load('../dat/features_train.mat');
load('weightToTrain.mat');

%% generate the features file
fp = fopen('train.txt', 'w');
for iTest = sort(randsample(1:length(histbar_calib), 20)) % length(histbar_calib)
    fnTest = strrep(features_train{iTest}.fn, ['1vertex'], '');
    for iTrain = 1: length(meshes)
        % work on the lower bound of the distance -- first seek for the
        % best possible feature alignment
        f = histbar_calib{iTest}; m = histbar_train{iTrain}; dists = zeros(param.divided, 1);
        for j = 1: param.divided
            dists(j) = sum(xor(f, m));  % this is distance, not similarity
            % rotate
            tmp = reshape(f, param.rings, numel(f) / param.rings);
            for k = 1: 21   % number of slices in total
                tmp(:, [(k - 1) * param.divided + 2: k * param.divided, (k - 1) * param.divided + 1]) = tmp(:, (k - 1) * param.divided + 1: k * param.divided);
            end
            f = reshape(tmp, numel(tmp), 1);
        end
        
        % generate the 'best' feature for the test data
        [~, id] = min(dists);
        f = histbar_calib{iTest};
        tmp = reshape(f, param.rings, numel(f) / param.rings);
        for j = 1: id - 1
            for k = 1: 21   % number of slices in total
                tmp(:, [(k - 1) * param.divided + 2: k * param.divided, (k - 1) * param.divided + 1]) = tmp(:, (k - 1) * param.divided + 1: k * param.divided);
            end
        end
        f = reshape(tmp, numel(tmp), 1);
        
        % find correct pairs and generate feature files
        fnTrain = strrep(meshes{iTrain}.fn, ['sweater1vertex'], '');
        if strcmp(fnTest, fnTrain)
            % is the correct pair
            fprintf('Correct pair!\n');
            fprintf(fp, '%d qid:%d ', 2, iTest);
        else
            fprintf(fp, '%d qid:%d ', 1, iTest);
        end
        % output the feature
        for i = find(xor(f, histbar_train{iTrain}))
            fprintf(fp, '%d:1 ', i);
        end
        fprintf(fp, '\n');
    end
end
fclose(fp);

%% invoke rank svm
if ismac || ispc
    error('only support linux for now.');
end
system(sprintf('python ranksvm.py %d', length(histbar_test{1})));
