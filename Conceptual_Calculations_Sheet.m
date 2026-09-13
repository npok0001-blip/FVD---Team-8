clear all, close all, clc
% Author: Nickhil Pokharel
% Unit: MAE4410
% Purpose: This sheet allows preliminary calculations for helicopter design

% NOTE: The following has been altered from Dr.Sinha's original slides OR,
% assumptions have been made:
% - prescribing max tip speed instead of max forward speed
% - log's have been assumed to be base 10
% - In friction coefficient formula I have adjusted the value from -0.05 to -0.5 as per page
    % 5 of https://ntrs.nasa.gov/api/citations/19830016201/downloads/19830016201.pdf
% - Note in slides formula in slide does not specify speed of sound but dimensions
    % don't work out otherwise for Profile drag method 1
% - I am unsure whether Reynolds number should be calculated for each
    % component as reynolds number changes per charecteristic length. In
    % parasitic drag calculation. If you change it, that would increase
    % parasitic drag. In this code I have set the drag coefficient for
    % external components and then taken their cross sectional area to
    % calculate drag
% - external weight is not a function of individual external component weights, it probably could be
% - Weights have been defined in forces and those are carried through
% formulas
% - The cubed in the forward power equation has been changed to a squared
% to be consistent with:
% https://ntrs.nasa.gov/api/citations/20110014334/downloads/20110014334.pdf.
% Also dimensional analysis supports this.

a = 5.73; % slope of lift curve (rad^-1), from slides
a_sound = 343; % speed of sound (m/s) (taken at SSL)

%% Input Parameters

% Some of this is determined by Rule of Thumb and empirical data (user may choose to adjust
% this data down the line for design iteration):

% Input data has been categorised depending on which stage it first appears
% below

% Stage 1: Weight and Power
g = 9.81; % Gravitational acceleration (m/s^2)
P_i = 5*10^6; % Engine Rating (W)
PSFC = 0.24/(3.6e6); % Power specific fuel consumption (kg/W/s) {3.6 is a conversion factor}
% Stage 2:
mission_time = 3*60*60; % Mission time (s)
% Stage 3:
W_ms_ext = 185; % external mission system weight (kg)
%NOTE: You could link this variable to external_components below and calculate weight
W_ms_int = 566; % internal mission system weight (kg)
W_c = 362; % Crew weight (kg)
W_p = 900; % Personnel weight (kg)
W_u_to_W_g = 0.55; % Useful weight to gross weight ratio. Rule of thumb from lecture slides
% Stage 4:
A_p = 60; % Projected area (m^2)
D_L = 58.59; % Disk Loading (kg/m^2), Note a multiplication with g has been included to convert to N. Which is required for later equations to work
D_L_Force = 58.59*g; % Disk Loading (kg/m^2), Note a multiplication with g has been included to convert to N. Which is required for later equations to work

% Stage 5:
mu = 0.4; % advance ratio
V_T = 0.65*a_sound; % prescribe a maximum allowable tip speed (m/s)
rho_SSL = 1.225; % air density at SSL (kg/m^3)
dynamic_viscosity = 1.789 * 10^-5; % (Pa/s) at SSL
R_to_c = 18; % radius to chord ratio
C_T_to_sigma = 0.17; % thrust coefficient to solidity ratio
% Stage 6:
k = 0.00000818; % Parasite Drag Gross Weight (less mission system external) Constant
Re_inf = 5e6; % Reynolds number in forward flight. Note: I am unsure whether Reynolds number should be calculated for each
    % component as reynolds number changes per charecteristic length. I
    % have calculated it per compenent and taken the length of the
    % component as charecteristic length.
if Re_inf < 10^5 % Re dependent friction coefficient
    C_f_inf = 1.3*Re_inf^(-0.5); % Re dependent friction coefficient;
    % NOTE: I have adjusted the above value from -0.05 to -0.5 as per page
    % 5 of https://ntrs.nasa.gov/api/citations/19830016201/downloads/19830016201.pdf
else
    C_f_inf = 0.45*(log10(Re_inf))^(-2.5);
    %NOTE: I have assumed it is log base 10 as per text books   
end

% Add or remove rows as required. Each row contains:
% component name, diameter (m), length (m), weight (kg)
external_components = {
     % Name                                  Diameter (m)   Length (m)   Weight (kg) 
    'Night sun',                               0.55,         0.51,        19;
    'Tail Rotor flood light',                  0.16,         0.06,        0.9;
    'Spotlights',                              0.01,         0.54,        0.9;
    'Rescue Hoist',                            0.52,         0.45,        28.6;
    % % Name                                  Diameter (m)   Length (m)   Weight (kg)
    % 'WESCAM MX-10 camera turret proxy',        0.254,         0.356,        17.2;
    % 'TrakkaBeam A800 searchlight proxy',       0.417,         0.478,        17.9;
    % 'Goodrich external rescue hoist',          0.311,         0.848,        48.0;
}; % I HAVE COMMMENTED THESE OUT FOR NOW AS I AM NOT SURE HOW TO TREAT REYNOLDS NUMBER FOR CALCULATION OF SKIN FRICTION FOR COMPONENTS

% Stage 7:
misc_power = 0.15; % miscellaneous power requirements



%% Stage 2: Fuel
W_f = PSFC * P_i * mission_time; % fuel weight (kg)

%% Stage 3: Weight
W_u = W_ms_ext + W_ms_int + W_c + W_p + W_f; % useful weight (kg)
W_g = W_u * W_u_to_W_g^(-1); % gross weight (kg)
W_g_Force = W_g * g; % gross weight (N)

%% Stage 4: Vertical Drag and Profile
D_v = 0.3 * D_L_Force * A_p; % Vertical Drag (N)

%% Stage 5: Main Rotor System
A_D = (W_g_Force + D_v)/D_L_Force; % Rotor area (m^2)
R = sqrt(A_D/pi); % Rotor radius (m)

omega = V_T/R; % Rotation speed of rotor (rad/s)
V_f = mu * omega * R; % Maximum forward speed (m/s)

c = R * R_to_c^(-1); % blade chord (m)

sigma = (W_g_Force + D_v)/(rho_SSL*A_D*(omega*R)^2*C_T_to_sigma); % Solidity
b = (sigma*pi*(R))/c; % number of blades


%% Stage 6: Drag in Forward Flight
C_dp_clean = k*(W_g - W_ms_ext)^(2/3);
d_ext_store = [];

C_dp_ext_components = zeros(size(external_components,1),1);
for i = 1:size(external_components,1)
    d_ext = external_components{i,2};
    d_ext_store(i) = d_ext; 
    L_ext = external_components{i,3};
    Re_comp = (rho_SSL * V_f * d_ext) / dynamic_viscosity; % Reynolds number in forward flight. Note: I am unsure if the charecteristic drag that has been taken here
    if Re_comp < 10^5 % Re dependent friction coefficient
    C_f_comp = 1.3*Re_comp^(-0.5); % Re dependent friction coefficient;
    % NOTE: I have adjusted the above value from -0.05 to -0.5 as per page
    % 5 of https://ntrs.nasa.gov/api/citations/19830016201/downloads/19830016201.pdf
    else
    C_f_comp = 0.45*(log10(Re_comp))^(-2.5);
    %NOTE: I have assumed it is log base 10 as per text books   
    end
    lambda_f = 1 + 1.5*(d_ext/L_ext)^1.5 + 7*(d_ext/L_ext)^3;
    C_dp_ext_components(i) = 1.15*lambda_f*C_f_comp;
    % C_dp_ext_components(i) = 0.1;
end
C_dp_ext = sum(C_dp_ext_components);

% C_dp = C_dp_clean + C_dp_ext; % Total parasitic drag coefficient
C_dp_clean; % Total parasitic drag coefficient

C_T = C_T_to_sigma * sigma; % Coefficient of thrust

alpha_av = ((6*C_T)/sigma)/a; % average angle of attack (rad) from the Slope-of-Lift-Curve

% Profile Drag Method 1:
M_075 = 0.75*omega*R/a_sound;
% NOTE: Formula in slide does not specify speed of sound but dimensions
% don't work out otherwise
alpha_av_deg = rad2deg(alpha_av);

% Approximate data digitised from the supplied profile-drag chart
alpha_chart = [0 2 4 5 6 8 9 10 12 13 14, ...
               0 2 4 5 6 8 9 10 12 13, ...
               0 2 4 5 6 8 9, ...
               0 2 4 5];
M_chart = [0.2*ones(1,11), 0.4*ones(1,10), ...
           0.6*ones(1,7), 0.8*ones(1,4)];
C_d0_chart = [0.009 0.009 0.009 0.010 0.011 0.013 0.015 0.016 0.019 0.024 0.040, ...
              0.009 0.009 0.009 0.010 0.011 0.015 0.019 0.025 0.060 0.078, ...
              0.009 0.009 0.009 0.014 0.028 0.050 0.070, ...
              0.015 0.020 0.048 0.078];
C_d0_interpolant = scatteredInterpolant(alpha_chart(:),M_chart(:), ...
    C_d0_chart(:),'linear','linear');
C_d0_1 = C_d0_interpolant(alpha_av_deg,M_075);

if M_075 < 0.2 || M_075 > 0.8 || alpha_av_deg < 0 || alpha_av_deg > 14
    warning('M_075 or alpha_av is outside the supplied profile-drag chart; C_d0_1 has been extrapolated.');
end

% Profile drag Method 2:
C_d0_2 = 0.0087 + 0.0126*alpha_av + 0.400*(alpha_av)^2;

% Profile drag Method 3:
C_d0_3 = 0.01 + 0.3*(alpha_av)^2;

% Take max of three methods
C_d0 = max([C_d0_1,C_d0_2,C_d0_3]);

%% Stage 7: Power required in forward flight
P_induced  = W_g_Force^2/(2*rho_SSL*A_D*V_f);
P_profile  = (sigma*C_d0*rho_SSL*A_D*(omega*R)^3*(1 + 4.65*mu^2))/8;
P_parasite = (rho_SSL*C_dp_clean*A_D*V_f^3)/2 + sum( (rho_SSL.*transpose(C_dp_ext_components).*pi.*((d_ext_store./2).^2).*V_f.^3)./2 );

Pf_minus_Pm = P_induced + P_profile + P_parasite;
Pf = Pf_minus_Pm * (1 + misc_power);

%% Refinement and Iteration

% Power requirements check
if Pf < P_i
    power_difference = (P_i - Pf)/1000;
    fprintf('\nPf is lower than Pi by %.3f kW.\n',power_difference);
    fprintf('o Re-select engine (Stage III)\n');
    fprintf(['o Re-evaluate gross weight, parasite drag of clean helicopter, ' ...
        'fuel weight with new sfc (Stage II, V & VI)\n']);
elseif Pf > P_i
    power_difference = (Pf - P_i)/1000;
    fprintf('\nPf is higher than Pi by %.3f kW.\n',power_difference);
    fprintf(['Reduce parasite drag - retractable landing gears, ' ...
        'external loads as internal loads\n']);
else
    fprintf('\nPf is equal to Pi.\n');
end

%% Output Parameters

fprintf('\nINPUT PARAMETERS\n');
fprintf('Engine rating: %.6g kW\n',P_i/1000);
fprintf('Power specific fuel consumption: %.6g kg/W/s\n',PSFC);
fprintf('Mission time: %.6g s\n',mission_time);
fprintf('External mission system weight: %.6g kg\n',W_ms_ext);
fprintf('Internal mission system weight: %.6g kg\n',W_ms_int);
fprintf('Crew weight: %.6g kg\n',W_c);
fprintf('Personnel weight: %.6g kg\n',W_p);
fprintf('Useful weight to gross weight ratio: %.6g\n',W_u_to_W_g);
fprintf('Projected area: %.6g m^2\n',A_p);
fprintf('Disk loading: %.6g N/m^2\n',D_L_Force);
fprintf('Advance ratio: %.6g\n',mu);
fprintf('Maximum allowable tip speed: %.6g m/s\n',V_T);
fprintf('Air density at standard sea level: %.6g kg/m^3\n',rho_SSL);
fprintf('Rotor radius to blade chord ratio: %.6g\n',R_to_c);
fprintf('Thrust coefficient to solidity ratio: %.6g\n',C_T_to_sigma);
fprintf('Parasite drag gross weight constant: %.6g\n',k);
fprintf('Reynolds number in forward flight: %.6g\n',Re_inf);
fprintf('Slope of lift curve: %.6g rad^-1\n',a);
fprintf('Speed of sound: %.6g m/s\n',a_sound);

if isempty(external_components)
    fprintf('External components: none entered\n');
else
    for i = 1:size(external_components,1)
        fprintf('External component %d name: %s\n',i,external_components{i,1});
        fprintf('External component %d diameter: %.6g m\n',i,external_components{i,2});
        fprintf('External component %d length: %.6g m\n',i,external_components{i,3});
        fprintf('External component %d weight: %.6g kg\n',i,external_components{i,4});
    end
end

fprintf('Miscellaneous power allowance: %.6g%%\n',100*misc_power);

fprintf('\nCALCULATED VALUES\n');
fprintf('Fuel weight: %.6g kg\n',W_f);
fprintf('Usable weight: %.6g kg\n',W_u);
fprintf('Gross weight: %.6g kg\n',W_g);
fprintf('Vertical drag: %.6g N\n',D_v);
fprintf('Rotor area: %.6g m^2\n',A_D);
fprintf('Rotor radius: %.6g m\n',R);
fprintf('Number of blades: %.6g \n',b);
% fprintf('Number of Blades: %.6g\n',G);
fprintf('Rotor angular velocity: %.6g rad/s\n',omega);
fprintf('Forward velocity: %.6g m/s\n',V_f);
fprintf('Blade chord: %.6g m\n',c);
fprintf('Total clean parasitic drag coefficient: %.6g\n',C_dp_clean);
fprintf('Thrust coefficient: %.6g\n',C_T);
fprintf('Profile drag coefficient: %.6g\n',C_d0);
fprintf('Induced power: %.6g W\n',P_induced);
fprintf('Profile power: %.6g W\n',P_profile);
fprintf('Parasite power: %.6g W\n',P_parasite);
fprintf('Total forward-flight power required: %.6g kW\n',Pf/1000);

(V_f+omega*R)/a_sound