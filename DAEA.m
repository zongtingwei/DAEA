function [solution, time, off, ofit, site, paretoAVE, tempVar] = DAEA(train_F, train_L, maxFES, sizep)
    fprintf('DAEA\n');                                       
    tic
    FES = 1;
    dim = size(train_F, 2);
    ofit = zeros(sizep, 2);
    paretoAVE = zeros(1, 2); % To save final result of the Pareto front
    
    %% Initialization
    Problem.N = sizep;
    Problem.D = dim;
    Problem.lower = zeros(1, Problem.D);
    Problem.upper = ones(1, Problem.D);
    Problem.encoding = 'binary';
    
    %% Generate initial population
    Population = InitializePopulation(Problem);

    %% Evaluate initial population
    for i = 1:Problem.N
        [ofit(i, 1), ofit(i, 2)] = FSKNNfeixiang(Population(i).decs, train_F, train_L);
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
    
    %% Main loop
    while FES <= maxFES
        %% Generate offspring
        Offspring = NicVariation(Problem, Population, train_F, train_L);
        
        %% Evaluate offspring
        for i = 1:size(Offspring, 1)
            % Ensure the index does not exceed the size of of ofit
            if i + sizep <= size(ofit, 1)
                ofit(i + sizep, 1), ofit(i + sizep, 2) = FSKNNfeixiang(Offspring(i, :), train_F, train_L);
            else
                break; % Exit the loop if the index is out of bounds
            end
        end
        
        %% Environmental selection
        Population = EnvironmentalSelection([Population, Offspring], Problem.N);
        
        %% Update solution and pareto front
        for i = 1:Problem.N
            [ofit(i, 1), ofit(i,2)] = FSKNNfeixiang(Population(i).decs, train_F, train_L);
        end
        [FrontNO, ~] = NDSort(ofit(:, 1:2), sizep);
        site = find(FrontNO == 1);
        solution = ofit(site, :);
        paretoAVE(1) = mean(solution(:, 1)); 
        paretoAVE(2) = mean(solution(:, 2));
        
        FES = FES + 1;
    end
    
    %% Finalization
    off = Population.decs; % Ensure off is the decision variables of the final population
    tempVar{1} = ofit; % All objective function values
    tempVar{2} = FrontNO; % All front numbers
    tempVar{3} = []; % All crowding distances
    tempVar{4} = []; % Other temporary variables if needed
    
    clear tAveError;
    clear tAveFea;
    clear tErBest;
    clear tThres;
    toc
    time = toc;
end

function Offspring = NicVariation(Problem, Population,train_F,train_L)
    Objs = Population.objs;    
    Decs = Population.decs;
    [N, D] = size(Decs);

    % Selecting parents
    T = max(4, ceil(N * 0.2));
    normObjs = (Objs - repmat(min(Objs,[],1), N, 1)) ./ repmat(max(Objs,[],1) - min(Objs,[],1), N, 1);
    ED = pdist2(normObjs, normObjs, 'euclidean');
    ED(logical(eye(length(ED)))) = inf;
    [~, INic] = sort(ED, 2);
    INic = INic(:, 1 : T);
    IP_1 = (1 : N);
    IP_2 = zeros(1, N);
    for i = 1 : N
        if rand < 0.8 % local mating
            IP_2(i) = INic(i, randi(T, 1));
        else % global mating
            IG = (1 : N);
            IG(i) = [];
            IP_2(i) = IG(randi(N - 1, 1));
        end
    end
    Parent_1 = Decs(IP_1, :);
    Parent_2 = Decs(IP_2, :);
    OffspringDec = Parent_1;

    % do crossover
    for i = 1 : N
        k = find(xor(Parent_1(i, :), Parent_2(i, :)));
        t = length(k);
        if t > 1
            j = k(randperm(t, randi(t - 1, 1)));
            OffspringDec(i, j) = Parent_2(i, j);
        end
    end

    % do mutation
    for i = 1 : N
        if rand < 0.2
            j1 = find(OffspringDec(i, :));
            j0 = find(~OffspringDec(i, :));
            k1 = rand(1, length(j1)) < 1 / (length(j1) + 1);
            k0 = rand(1, length(j0)) < 1 / (length(j0) + 1);
            OffspringDec(i, j1(k1)) = false;
            OffspringDec(i, j0(k0)) = true;
        else
            k = rand(1, D) < 1 / D;
            OffspringDec(i, k) = ~OffspringDec(i, k);
        end
    end

    % get unique offspring and individuals
    OffspringDec = unique(OffspringDec, 'rows', 'stable');

    % Evaluate offspring
    OffspringObj = zeros(size(OffspringDec, 1), 2); 
    OffspringCon = zeros(size(OffspringDec, 1), 1); 
    for i = 1:size(OffspringDec, 1)
        OffspringObj(i, :) = FSKNNfeixiang(OffspringDec(i, :), train_F, train_L);
    end

    % Create SOLUTION objects
    Offspring = SOLUTION(OffspringDec, OffspringObj, OffspringCon);
end

function Population = InitializePopulation(Problem)
    T = min(Problem.D, Problem.N * 3);
    PopDec = zeros(Problem.N, Problem.D); 
    PopObj = zeros(Problem.N, 2); 
    PopCon = zeros(Problem.N, 1); 
    
    for i = 1 : Problem.N
        k = randperm(T, 1);
        j = randperm(Problem.D, k);
        PopDec(i, j) = 1;
    end
    
    Population = SOLUTION(PopDec, PopObj, PopCon);
end

function Population = EnvironmentalSelection(Population, N)
    % Get unique individuals in decision space
    [~, U_Decs, ~] = unique(Population.decs, 'rows');
    UP = Population(U_Decs);
    Objs = UP.objs;
    Decs = UP.decs;

    if length(UP) > N 
        % Calculate solution difference in decision space
        SD = pdist2(Decs, Decs, 'cityblock');
        SD(logical(eye(length(SD)))) = inf;

        % remove some duplicated solutions in objective space
        [U_Objs, ~, I_Objs] = unique(Objs, 'rows');
        duplicated = [];
        D = size(Decs, 2);
        for i = 1 : size(U_Objs, 1)
            j = find(I_Objs == i);
            if length(j) > 1
                t = sum(Decs(j(1), :));
                d = min(SD(j, j), [], 2) / 2;
                p = d / t;
                r = find(p < 0.8 - 0.6 * (t - 1) / (D - 1));
                if ~isempty(r)
                    duplicated = [duplicated; j(r(randperm(length(r), length(r) - 1)))];
                end
            end
        end

        % reset population
        if length(UP) - length(duplicated) > N
            UP(duplicated) = [];
            Objs = UP.objs;
        end

        % nondominated sorting
        [Front, MaxF] = NDSort(Objs, N); 
        Selected = Front < MaxF;
        Candidate = Front == MaxF;

        % Calculate crowding distance
        CD = CrowdingDistance(Objs,Front);

        % select last front
        while sum(Selected) < N
            S = Objs(Selected, 1);
            IC = find(Candidate);
            [~, ID] = sort(CD(IC), 'descend');
            IC = IC(ID);
            C = Objs(IC, 1);
            Div_Vert = zeros(1, length(C));
            for i = 1 : length(C)
                Div_Vert(i) = length(find(S == C(i)));
            end
            [~, IDiv_Vert] = sort(Div_Vert);
            IS = IC(IDiv_Vert(1));
            % reset Selected and Candidate
            Selected(IS) = true;
            Candidate(IS) = false;
        end
        Population = UP(Selected);
    else
        Population = [UP, Population(randperm(length(Population), (N - length(UP))))];
    end
end

