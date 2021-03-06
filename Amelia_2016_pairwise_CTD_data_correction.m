% Glider CTD data correction (only conductivity cell thermal lag correction)
% Daniel Haixing Wang
% July 2019
% apply method to Amelia 2016 Washington Canyon survey dataset. August, 2019. Haixing

% compare to early version, the 2019_07 version omits the sensor lag correction step.
% instead of using findSensorLagParams.m, the 2019 version uses Fofonoff (1974) equation.
% see Johnson et al. 2007 paper, Kerfoot et al. 2019 poster


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% need to make sure whether the following processure, exactly matches Kerfoot 2019.
% after checking the findThermalLagParams.m function, I think it uses the same method.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% re-store pair-wise correction data structures
pair_wise_cor_downcast = strictly_filtered_raw_downcast;

pair_wise_cor_upcast = strictly_filtered_raw_upcast;

%% use glider_toolbox_master findThermalLagParams.m and correctThermalLag.m to correct thermal lag for conductivity cell
% Note this step, thermal lag correction, is for conductivity measurements
% in the conductivity cell. We will get temperature inside the conducivity
% cell and conductivity outside of the conductivity cell from the procedure.

n_pair = size(strictly_filtered_down_up_pair_indices,1);

for ii = 1:n_pair
    pair_wise_cor_downcast(ii).ThermalLagParams = ...
        findThermalLagParams(pair_wise_cor_downcast(ii).t, ...
        pair_wise_cor_downcast(ii).cond, ...
        pair_wise_cor_downcast(ii).temp_True, ...
        pair_wise_cor_downcast(ii).pres,...
        pair_wise_cor_upcast(ii).t, ...
        pair_wise_cor_upcast(ii).cond, ...
        pair_wise_cor_upcast(ii).temp_True, ...
        pair_wise_cor_upcast(ii).pres);
    
    [pair_wise_cor_downcast(ii).temp_inside, pair_wise_cor_downcast(ii).cond_outside] = ...
        correctThermalLag_haixing(pair_wise_cor_downcast(ii).t, ...
        pair_wise_cor_downcast(ii).cond, ...
        pair_wise_cor_downcast(ii).temp_True, ...
        pair_wise_cor_downcast(ii).ThermalLagParams);
    
    pair_wise_cor_upcast(ii).ThermalLagParams = pair_wise_cor_downcast(ii).ThermalLagParams;
    
    [pair_wise_cor_upcast(ii).temp_inside, pair_wise_cor_upcast(ii).cond_outside] = ...
        correctThermalLag_haixing(pair_wise_cor_upcast(ii).t, ...
        pair_wise_cor_upcast(ii).cond, ...
        pair_wise_cor_upcast(ii).temp_True, ...
        pair_wise_cor_upcast(ii).ThermalLagParams);
end % for ii = 1:n_pair

%% store thermal lag parameters alpha and tau

for ii = 1:n_pair

alpha(ii) = pair_wise_cor_downcast(ii).ThermalLagParams(1);
tau(ii) = pair_wise_cor_downcast(ii).ThermalLagParams(2);
end

%% Use thermal-lag-corrected temmperature inside the conductivity cell, and conductivity inside the conductivity cell to calculate salinity
for ii = 1:n_pair
    % downcasts
    pair_wise_cor_downcast(ii).salt_cor_inside = ...
        gsw_SP_from_C(pair_wise_cor_downcast(ii).cond*10, ...
        pair_wise_cor_downcast(ii).temp_inside, ...
        pair_wise_cor_downcast(ii).pres*10); % salinity, converting pressure from bar to dbar and conductivity from S/m to mS/cm.
    
    pair_wise_cor_downcast(ii).saltA_cor_inside = ...
        gsw_SA_from_SP(pair_wise_cor_downcast(ii).salt_cor_inside, ...
        pair_wise_cor_downcast(ii).pres*10, ...
        pair_wise_cor_downcast(ii).lon,pair_wise_cor_downcast(ii).lat); % absolute salinity, converting pressure from bar to dbar
    
    pair_wise_cor_downcast(ii).ctemp_cor_inside = ...
        gsw_CT_from_t(pair_wise_cor_downcast(ii).saltA_cor_inside, ...
        pair_wise_cor_downcast(ii).temp_inside, ...
        pair_wise_cor_downcast(ii).pres*10); % conservative temperature, converting pressure from bar to dbar
    
    pair_wise_cor_downcast(ii).ptemp_cor_inside = ...
        gsw_pt_from_CT(pair_wise_cor_downcast(ii).saltA_cor_inside, ...
        pair_wise_cor_downcast(ii).ctemp_cor_inside); % potential temperature
    
    pair_wise_cor_downcast(ii).rho_cor_inside = ...
        gsw_rho(pair_wise_cor_downcast(ii).saltA_cor_inside, ...
        pair_wise_cor_downcast(ii).ctemp_cor_inside, ...
        pair_wise_cor_downcast(ii).pres); % in-situ density
    
    pair_wise_cor_downcast(ii).sigma0_cor_inside = ...
        gsw_sigma0(pair_wise_cor_downcast(ii).saltA_cor_inside, ...
        pair_wise_cor_downcast(ii).ctemp_cor_inside); % potential density anomaly
    
    % bug in Tuner angle calculation; will fix later
%      % Tuner angle
%     [pair_wise_cor_downcast(ii).Tu_inside, pair_wise_cor_downcast(ii).R_rho_inside, pair_wise_cor_downcast(ii).Pmid_Tu_inside] = ...
%         gsw_Turner_Rsubrho(pair_wise_cor_downcast(ii).saltA_cor_inside, ...
%         pair_wise_cor_downcast(ii).ctemp_cor_inside, ...
%         pair_wise_cor_downcast(ii).pres);
%     
%    % Buoyancy frequency
%     [pair_wise_cor_downcast(ii).N2_inside, pair_wise_cor_downcast(ii).Pmid_N2_inside] = ...
%         gsw_Nsquared(pair_wise_cor_downcast(ii).saltA_cor_inside, ...
%         pair_wise_cor_downcast(ii).ctemp_cor_inside, ...
%         pair_wise_cor_downcast(ii).pres, pair_wise_cor_downcast(ii).lat);
    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % upcasts
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pair_wise_cor_upcast(ii).salt_cor_inside = ...
        gsw_SP_from_C(pair_wise_cor_upcast(ii).cond*10, ...
        pair_wise_cor_upcast(ii).temp_inside, ...
        pair_wise_cor_upcast(ii).pres*10); % salinity, converting pressure from bar to dbar and conductivity from S/m to mS/cm.
    
    pair_wise_cor_upcast(ii).saltA_cor_inside = ...
        gsw_SA_from_SP(pair_wise_cor_upcast(ii).salt_cor_inside, ...
        pair_wise_cor_upcast(ii).pres*10, ...
        pair_wise_cor_upcast(ii).lon,pair_wise_cor_upcast(ii).lat); % absolute salinity, converting pressure from bar to dbar
    
    pair_wise_cor_upcast(ii).ctemp_cor_inside = ...
        gsw_CT_from_t(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
        pair_wise_cor_upcast(ii).temp_inside, ...
        pair_wise_cor_upcast(ii).pres*10); % conservative temperature, converting pressure from bar to dbar
    
    pair_wise_cor_upcast(ii).ptemp_cor_inside = ...
        gsw_pt_from_CT(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
        pair_wise_cor_upcast(ii).ctemp_cor_inside); % potential temperature
    
    pair_wise_cor_upcast(ii).rho_cor_inside = ...
        gsw_rho(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
        pair_wise_cor_upcast(ii).ctemp_cor_inside, ...
        pair_wise_cor_upcast(ii).pres); % in-situ density
    
    pair_wise_cor_upcast(ii).sigma0_cor_inside = ...
        gsw_sigma0(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
        pair_wise_cor_upcast(ii).ctemp_cor_inside); % potential density anomaly
    
%              % Tuner angle
%     [pair_wise_cor_upcast(ii).Tu_inside, pair_wise_cor_upcast(ii).R_rho_inside, pair_wise_cor_upcast(ii).Pmid_Tu_inside] = ...
%         gsw_Turner_Rsubrho(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
%         pair_wise_cor_upcast(ii).ctemp_cor_inside, ...
%         pair_wise_cor_upcast(ii).pres);
%     
%    % Buoyancy frequency
%     [pair_wise_cor_upcast(ii).N2_inside, pair_wise_cor_upcast(ii).Pmid_N2_inside] = ...
%         gsw_Nsquared(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
%         pair_wise_cor_upcast(ii).ctemp_cor_inside, ...
%         pair_wise_cor_upcast(ii).pres, pair_wise_cor_upcast(ii).lat);
    
    end % for ii = 1:n_pair
    
    %% Use thermal-lag-corrected temmperature outside the conductivity cell, and conductivity outside the conductivity cell to calculate salinity
for ii = 1:n_pair
    % downcasts
    pair_wise_cor_downcast(ii).salt_cor_outside = ...
        gsw_SP_from_C(pair_wise_cor_downcast(ii).cond_outside*10, ...
        pair_wise_cor_downcast(ii).temp_True, ...
        pair_wise_cor_downcast(ii).pres*10); % salinity, converting pressure from bar to dbar and conductivity from S/m to mS/cm.
    
    pair_wise_cor_downcast(ii).saltA_cor_outside = ...
        gsw_SA_from_SP(pair_wise_cor_downcast(ii).salt_cor_outside, ...
        pair_wise_cor_downcast(ii).pres*10, ...
        pair_wise_cor_downcast(ii).lon,pair_wise_cor_downcast(ii).lat); % absolute salinity, converting pressure from bar to dbar
    
    pair_wise_cor_downcast(ii).ctemp_cor_outside = ...
        gsw_CT_from_t(pair_wise_cor_downcast(ii).saltA_cor_outside, ...
        pair_wise_cor_downcast(ii).temp_True, ...
        pair_wise_cor_downcast(ii).pres*10); % conservative temperature, converting pressure from bar to dbar
    
    pair_wise_cor_downcast(ii).ptemp_cor_outside = ...
        gsw_pt_from_CT(pair_wise_cor_downcast(ii).saltA_cor_outside, ...
        pair_wise_cor_downcast(ii).ctemp_cor_outside); % potential temperature
    
    pair_wise_cor_downcast(ii).rho_cor_outside = ...
        gsw_rho(pair_wise_cor_downcast(ii).saltA_cor_outside, ...
        pair_wise_cor_downcast(ii).ctemp_cor_outside, ...
        pair_wise_cor_downcast(ii).pres); % in-situ density
    
    pair_wise_cor_downcast(ii).sigma0_cor_outside = ...
        gsw_sigma0(pair_wise_cor_downcast(ii).saltA_cor_outside, ...
        pair_wise_cor_downcast(ii).ctemp_cor_outside); % potential density anomaly
    
%     % Tuner angle
%     [pair_wise_cor_downcast(ii).Tu_outside, pair_wise_cor_downcast(ii).R_rho_outside, pair_wise_cor_downcast(ii).Pmid_Tu_outside] = ...
%         gsw_Turner_Rsubrho(pair_wise_cor_downcast(ii).saltA_cor_outside, ...
%         pair_wise_cor_downcast(ii).ctemp_cor_outside, ...
%         pair_wise_cor_downcast(ii).pres);
%     
%    % Buoyancy frequency
%     [pair_wise_cor_downcast(ii).N2_outside, pair_wise_cor_downcast(ii).Pmid_N2_outside] = ...
%         gsw_Nsquared(pair_wise_cor_downcast(ii).saltA_cor_outside, ...
%         pair_wise_cor_downcast(ii).ctemp_cor_outside, ...
%         pair_wise_cor_downcast(ii).pres, pair_wise_cor_downcast(ii).lat);
   
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % upcasts
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    pair_wise_cor_upcast(ii).salt_cor_outside = ...
        gsw_SP_from_C(pair_wise_cor_upcast(ii).cond_outside*10, ...
        pair_wise_cor_upcast(ii).temp_True, ...
        pair_wise_cor_upcast(ii).pres*10); % salinity, converting pressure from bar to dbar and conductivity from S/m to mS/cm.
    
    pair_wise_cor_upcast(ii).saltA_cor_outside = ...
        gsw_SA_from_SP(pair_wise_cor_upcast(ii).salt_cor_outside, ...
        pair_wise_cor_upcast(ii).pres*10, ...
        pair_wise_cor_upcast(ii).lon,pair_wise_cor_upcast(ii).lat); % absolute salinity, converting pressure from bar to dbar
    
    pair_wise_cor_upcast(ii).ctemp_cor_outside = ...
        gsw_CT_from_t(pair_wise_cor_upcast(ii).saltA_cor_outside, ...
        pair_wise_cor_upcast(ii).temp_True, ...
        pair_wise_cor_upcast(ii).pres*10); % conservative temperature, converting pressure from bar to dbar
    
    pair_wise_cor_upcast(ii).ptemp_cor_outside = ...
        gsw_pt_from_CT(pair_wise_cor_upcast(ii).saltA_cor_outside, ...
        pair_wise_cor_upcast(ii).ctemp_cor_outside); % potential temperature
    
    pair_wise_cor_upcast(ii).rho_cor_outside = ...
        gsw_rho(pair_wise_cor_upcast(ii).saltA_cor_outside, ...
        pair_wise_cor_upcast(ii).ctemp_cor_outside, ...
        pair_wise_cor_upcast(ii).pres); % in-situ density
    
    pair_wise_cor_upcast(ii).sigma0_cor_outside = ...
        gsw_sigma0(pair_wise_cor_upcast(ii).saltA_cor_outside, ...
        pair_wise_cor_upcast(ii).ctemp_cor_outside); % potential density anomaly
    
%              % Tuner angle
%     [pair_wise_cor_upcast(ii).Tu_inside, pair_wise_cor_upcast(ii).R_rho_inside, pair_wise_cor_upcast(ii).Pmid_Tu_inside] = ...
%         gsw_Turner_Rsubrho(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
%         pair_wise_cor_upcast(ii).ctemp_cor_inside, ...
%         pair_wise_cor_upcast(ii).pres);
%     
%    % Buoyancy frequency
%     [pair_wise_cor_upcast(ii).N2_inside, pair_wise_cor_upcast(ii).Pmid_N2_inside] = ...
%         gsw_Nsquared(pair_wise_cor_upcast(ii).saltA_cor_inside, ...
%         pair_wise_cor_upcast(ii).ctemp_cor_inside, ...
%         pair_wise_cor_upcast(ii).pres, pair_wise_cor_upcast(ii).lat);
    
    end % for ii = 1:n_pair



save amelia_2016_glider_CTD_data_correction_workspace_2019_08





