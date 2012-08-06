clc;
clear all;
close all;

%% TUNABLE PARAMETERS %%

mexEnabled = 1;             % Enable the C++ version of the decoder
backSubstitution = 1;       % Enable encoding by back substitution

% Parameters presets:
% 0: BER vs iteration test
% 1: Rate 1/2 accurate BER and FER test
% 2: Rate 1/2 longer input, less accurate BER and FER test
% 3: Rate comparison, less accurate BER and FER test
% 4: Manual
 preset = 1;

% Manual mode parameters
mu = 10^6;               % Input length
R = 1/2;                 % Code rate. Available rates 1/2, 2/3, 3/4, 5/6
iter = 1 ;               % Number of simulations (100 for good results)
EbN0step = 0.25;         % Set to 0.5 to speed things up
EbN0dB = 1:EbN0step:2.5; %Eb/N0 values


%% PRESET %%

switch preset
    case 0,
        mu = 10^6;
        R = 1/2;
        iter = 20;
        ldpcIter = 1:50;
        EbN0dB = 2.5;
    case 1,
        mu = 10^6;
        R = 1/2;
        iter = 5;
        EbN0dB = 1:EbN0step:2.5;                
    case 2,
        mu = 10^7;
        R = 1/2;
        iter = 2;
        EbN0dB = 1:EbN0step:2.5;        
    case 3,
        mu = 10^6;
        R = [1/2, 2/3, 3/4, 5/6];
        iter = 24;
        EbN0dB = 1:EbN0step:2.5;        
end


%% SIMULATION %%

ber_ldpc = zeros(iter,length(EbN0dB),length(R));
fer_ldpc = zeros(iter,length(EbN0dB),length(R));

tic
if ~preset
    gammaDB = EbN0dB + 10*log(2*R);
    for i=1:length(ldpcIter)
        parfor j=1:iter
            u_input = round(rand(1,mu));       % Random input sequence
            [u_output, ber_ldpc(i,j), fer_ldpc(i,j)] = ldpcTxSystem( u_input, R, gammaDB, mexEnabled, backSubstitution, ldpcIter(j));
        end    
    end    
    ber_ldpc = sum(ber_ldpc,2)/iter;
    fer_ldpc = sum(fer_ldpc,2)/iter;            
else
    for i=1:length(R)
        gammaDB = EbN0dB + 10*log(2*R(i));
        for j=1:length(gammaDB)
            parfor k=1:iter                
                u_input = round(rand(1,mu));       % Random input sequence
                [u_output, ber_ldpc(i,j,k), fer_ldpc(i,j,k)] = ldpcTxSystem( u_input, R(i), gammaDB(j), mexEnabled, backSubstitution);                
            end            
        end
    end    
    ber_ldpc = sum(ber_ldpc,3)/iter;
    fer_ldpc = sum(fer_ldpc,3)/iter;
end
time = toc        


%% SAVE DATA %%
if ~exist('output','dir')
    mkdir('output');
end
save('output/workspace');


%% PLOT %%

if ~preset
    plotLDPC(ldpcIter, ber_ldpc, fer_ldpc, 1);
else
    plotLDPC(EbN0dB, ber_ldpc, fer_ldpc);
end
