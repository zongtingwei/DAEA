function [solution, time, off, ofit, site, paretoAVE, tempVar, bitImportance] = DAEA(train_F, train_L, maxFES, sizep)
    fprintf('DAEA');                                       
    tic
    FES = 1;
    dim = size(train_F, 2);
    ofit = zeros(sizep, 2);
    paretoAVE = zeros(1, 2); % To save final result of the Pareto front
    
    %% Initialization
    Dec = ones(sizep, dim);
    Mask = zeros(sizep, dim);
    for i = 1 : sizep
        Mask(i, TournamentSelection(2, ceil(rand * dim), zeros(1, dim))) = 1; 
    end
    off = logical(Dec.*Mask);
    
    %% Evaluate
    for i = 1 : sizep
        [ofit(i, 1), ofit(i, 2)] = FSKNNfeixiang(off(i, :), train_F, train_L);
    end
    [FrontNO, ~] = NDSort(ofit(:, 1:2), sizep);
    site = find(FrontNO == 1);
    solution = ofit(site, :);
    solution(:, 2) = solution(:, 2) / dim;
    disp('Solution:');
    disp(solution);
    erBestParetoAVE = 1;  % To save the history best
    paretoAVE(1) = mean(solution(:, 1));
    paretoAVE(2) = mean(solution(:, 2));
    
    %% Calculate bitImportance
    MI = zeros(1, dim);
    for i = 1 : dim
        MI(i) = MItest(train_F(:, i), train_L);
    end
    DR = zeros(1, sizep);
    for i = 1 : sizep
        DR(i) = sum(FrontNO > FrontNO(i));
    end
    DR = DR ./ sizep;
    bitImportance = zeros(sizep, dim);
    for i = 1 : sizep
        for j = 1 : dim
            bitImportance(i, j) = MI(j) * DR(i) / (sum(MI) * sizep);
        end
    end
    
    %% Main loop
    while FES <= maxFES
        isChange = zeros(sizep, dim); 
        extTemp = 0; 
        
        %---------------- Dimensionality reduction ---------------
        for i = 1 : sizep
            if ismember(i, site)
                continue;
            end
            
            curiOff = off(i, :); 
            curpSite = site(randi(length(site))); 
            pop = off(curpSite, :); 
            
            aveiBit = mean(bitImportance(i, :));
            
            for j = 1 : dim
                popBit = pop(j);
                ext = 1 / (1 + exp(-5 * (aveiBit - bitImportance(i, j))));
                tempThres = 1 * exp(-0.1 * FES);
                ext = ext * tempThres;
                if rand() < ext
                    off(i, j) = 0; 
                end
                extTemp = extTemp + ext;
                
                %----- Individual repairing -----
                if bitImportance(i, j) > bitImportance(curpSite, j)
                    off(i, j) = curiOff(j); 
                else
                    if rand() < (bitImportance(curpSite, j) - bitImportance(i, j)) / bitImportance(curpSite, j)
                        off(i, j) = popBit;
                    end
                end
                
                if curiOff(j) ~= off(i, j)
                    isChange(i, j) = 1;
                end
         
            end         
        end
        extTemp = extTemp / dim / sizep;
        
        %--------------- Evaluate ----------------
        for i = 1 : sizep
            [ofit(i, 1), ofit(i, 2)] = FSKNNfeixiang(off(i, :), train_F, train_L);
         
        end
        [FrontNO, ~] = NDSort(ofit(:, 1:2), sizep);
        site = find(FrontNO == 1);
        solution = ofit(site, :);
        oldERAVE = paretoAVE(1);
        paretoAVE(1) = mean(solution(:, 1)); 
        paretoAVE(2) = mean(solution(:, 2));
        if paretoAVE(1) < erBestParetoAVE
            erBestParetoAVE = paretoAVE(1); 
        end
        
        %---- Update bitImportance ----
        oldBI = bitImportance;
        for i = 1 : sizep
            for j = 1 : dim
                bitImportance(i, j) = 0.7 * oldBI(i, j) + 0.3 * MI(j) * DR(i) / (sum(MI) * sizep);
            end
        end
        
        fprintf('PRG: %.1f%%-- GEN: %2d  Error: %.5f  F: %.2f     ErBest: %.5f     thres: %.5f\n',100*((FES-1)/maxFES), FES,paretoAVE(1),paretoAVE(2),ofit(site(1),1),extTemp);
        FES = FES + 1;
    end
    %%
    
    [FrontNO,~] = NDSort(ofit(:,1:2),sizep);
    site = find(FrontNO==1);
    solution = ofit(site,:);
    
    paretoAVE(1) = mean(solution(:,1));
    paretoAVE(2) = mean(solution(:,2));
    
    % Define and calculate tAveError, tAveFea, tErBest, tThres
    tAveError = paretoAVE(1);  % Average error
    tAveFea = paretoAVE(2);    % Average features
    tErBest = erBestParetoAVE; % Best error
    tThres = extTemp;          % Threshold
    
    tempVar{1} = tAveError;
    tempVar{2} = tAveFea;
    tempVar{3} = tErBest;
    tempVar{4} = tThres;
    
    clear tAveError;
    clear tAveFea;
    clear tErBest;
    clear tThres;
    toc
    time = toc;
end

