clear all, close all, 
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
P_i = 1938.8*10^3; % Engine Rating (W)
PSFC = 0.24/(3.6e6); % Power specific fuel consumption (kg/W/s) {3.6 is a conversion factor}
% Stage 2:
mission_time = 1*60*60; % Mission time (s)
% Stage 3:

%NOTE: You could link this variable to external_components below and calculate weight
W_ms_int = 50; % internal mission system weight (kg)
W_c = 200; % Crew weight (kg)
W_p = 870; % Personnel weight (kg)
W_u_to_W_g = 0.31; % Useful weight to gross weight ratio. Rule of thumb from lecture slides
% Stage 4:
num_rotors = 2;
A_p = 20; % Projected area (m^2)
D_L = 30; % Disk Loading (kg/m^2), Note a multiplication with g has been included to convert to N. Which is required for later equations to work
D_L_Force= D_L*g; % Disk Loading (N/m^2), This is required for later equations to work

% Stage 5:
mu = 0.5659; % advance ratio
% V_T = 0.65*a_sound; % prescribe a maximum allowable tip speed (m/s)
% V_F = mu*V_T; 
V_f = 113.178; %m/s prescribed max forward speed.
V_T = V_f/mu; % m/s Tip speed
rho_SSL = 1.225; % air density at SSL (kg/m^3)
dynamic_viscosity = 1.789 * 10^-5; % (Pa/s) at SSL
R_to_c = 18; % radius to chord ratio
C_T_to_sigma = 0.10; % thrust coefficient to solidity ratio. NOTE:this has been adjusted as per literature, it was quite aggresive before
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
    % 'Night sun',                               0.55,         0.51,        19;
    % 'Tail Rotor flood light',                  0.16,         0.06,        0.9;
    % 'Spotlights',                              0.10,         0.54,        0.9;
    % 'Rescue Hoist',                            0.52,         0.45,        28.6;
    % % Name                                  Diameter (m)   Length (m)   Weight (kg)
    % 'WESCAM MX-10 camera turret proxy',        0.254,         0.356,        17.2;
    % 'TrakkaBeam A800 searchlight proxy',       0.417,         0.478,        17.9;
    % 'Goodrich external rescue hoist',          0.311,         0.848,        48.0;
}; % I HAVE COMMMENTED THESE OUT FOR NOW AS I AM NOT SURE HOW TO TREAT REYNOLDS NUMBER FOR CALCULATION OF SKIN FRICTION FOR COMPONENTS
% W_ms_ext = external_components{:,4}; % external mission system weight (kg)
W_ms_ext = 0; % external mission system weight (kg)


% Stage 7:
k_int_coincident_rotor_planes = sqrt(2);
k_int_lower_rotor_in_fullwake = 1.28; %supported by literature for compact first hover model
misc_power = 0.15; % miscellaneous power requirements
mechanical_power_losses = 0.15; %power losses transmitting power to rear pusher

% Stage 8: Rear Prop sizing:
P_installed_total = P_i;     % TOTAL installed shaft power, all engines [W]  <-- CONFIRM
eta_drive = 1 - mechanical_power_losses;
eta_prop          = 0.85;    % propeller efficiency relative to ideal (assumed 0.80-0.90)
d_min             = 0.6;     % propeller diameter sweep [m]
d_max             = 4.0;     % 
n_points          = 100;

V = V_f;            % forward speed [m/s]

%% Stage 2: Fuel
W_f = PSFC * P_i * mission_time; % fuel weight (kg)

%% Stage 3: Weight
W_u = W_ms_ext + W_ms_int + W_c + W_p + W_f; % useful weight (kg)
W_g = W_u * W_u_to_W_g^(-1); % gross weight (kg)
W_g_Force = W_g * g; % gross weight (N)

%% Stage 4: Vertical Drag and Profile
D_v = 0.3 * D_L_Force * A_p; % Vertical Drag (N)
T_total = W_g_Force + D_v;
T_per_coax = T_total/num_rotors;

%% Stage 5 - Single Rotor: Main Rotor System
A_D_single = (T_total)/(D_L_Force); % Rotor area (m^2)
R_single = sqrt(A_D_single/pi); % Rotor radius (m)

% omega_single = V_T/R_single; % Rotation speed of rotor (rad/s)
% V_f_single = mu * omega_single * R_single; % Maximum forward speed (m/s)

omega_single = V_f / (mu*R_single);
V_T_single = omega_single*R_single;


c_single = R_single * R_to_c^(-1); % blade chord (m)

sigma_single = (T_total)/(rho_SSL*A_D_single*(omega_single*R_single)^2*C_T_to_sigma); % Solidity
b_single = (sigma_single*pi*(R_single))/c_single; % number of blades
b_single_actual = ceil(b_single);
c_single_actual = pi*R_single*sigma_single/ b_single_actual;

%% Stage 5 - Coaxial Rotor: Main Rotor System
A_D_per_coax = (T_per_coax)/(D_L_Force); % Rotor area (m^2)
R_per_coax = sqrt(A_D_per_coax/pi); % Rotor radius (m)

% omega_per_coax = V_T/R_per_coax; % Rotation speed of rotor (rad/s)
% V_f_per_coax = mu * omega_per_coax * R_per_coax; % Maximum forward speed (m/s)

omega_per_coax = V_f / (mu*R_per_coax);
V_T_coax = omega_per_coax*R_per_coax;

c_per_coax = R_per_coax * R_to_c^(-1); % blade chord (m)

sigma_per_coax = (T_per_coax)/(rho_SSL*A_D_per_coax*(omega_per_coax*R_per_coax)^2*C_T_to_sigma); % Solidity
b_per_coax = (sigma_per_coax*pi*(R_per_coax))/c_per_coax; % number of blades
b_per_coax_actual = ceil(b_per_coax);
c_per_coax_actual = pi*R_per_coax*sigma_per_coax/ b_per_coax_actual;

%% Stage 6: Drag in Forward Flight
C_dp_clean = k*(W_g - W_ms_ext)^(2/3);
A_ref_clean = A_D_single;                    % the disk area k was calibrated against rotor diameter if single rotor 
                                        % this need to be done in order to compare across different configs and to
                                        % align with lecture notes
f_clean = C_dp_clean * A_ref_clean;       % clean airframe drag area [m^2]

d_ext_store = [];
C_dp_ext_components = zeros(size(external_components,1),1);


% NOTE: This approach is from the lecture slides but is kinda dodgy. For example,
% for long objects. Determining drag using frontal area does not seem like
% the correct approach, should it not depend on wetted area? For example,
% if you have two cylinders of identical cross section but one is longer,
% should the latter not have a higher drag coeff?
for i = 1:size(external_components,1)
    d_ext = external_components{i,2}; 
    L_ext = external_components{i,3};
    d_ext_store(i) = d_ext;
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
% C_dp_ext = sum(C_dp_ext_components.*d_on_l_store);
% C_dp = C_dp_clean + C_dp_ext; % Total parasitic drag coefficient
% C_dp_clean; % Total parasitic drag coefficient

% In the same way as clean drag, define equipment parasitic drag area
f_equip = sum( C_dp_ext_components(:) .* pi .* (d_ext_store(:)/2).^2 );  % [m^2], counted once
f_total = f_clean + f_equip; %total friction drag area

C_T = C_T_to_sigma * sigma_per_coax; % Coefficient of thrust

alpha_av = ((6*C_T)/sigma_per_coax)/a; % average angle of attack (rad) from the Slope-of-Lift-Curve

% Profile Drag Method 1:
M_075 = 0.75*omega_per_coax*R_per_coax/a_sound;
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
C_d0 = mean([C_d0_1,C_d0_2,C_d0_3]);

%% Stage 7: Power required in forward flight

% Shared induced velocity, based on TOTAL thrust and ONE rotor disk area.
% SEE: https://eaglepubs.erau.edu/introductiontoaerospaceflightvehicles/chapter/helicopters
v_induced_cruise = T_total / ...
    (2*rho_SSL*A_D_per_coax*V_f);

% Power required by each rotor, then summed across both rotors.
% Cruise thrust, separate from hover sizing.
T_cruise_total = W_g_Force;
T_cruise_per_coax = T_cruise_total / num_rotors;

v_induced_cruise = T_cruise_total / ...
    (2*rho_SSL*A_D_per_coax*V_f);

P_induced_per_coax = T_cruise_per_coax * v_induced_cruise;
P_induced = P_induced_per_coax * num_rotors;
P_profile_per_coax  = (sigma_per_coax*C_d0*rho_SSL*A_D_per_coax*(omega_per_coax*R_per_coax)^3*(1 + 4.65*mu^2))/8;
P_profile  = P_profile_per_coax*num_rotors;
% P_parasite_per_coax = (rho_SSL*C_dp_clean*A_D_per_coax*V_f_per_coax^3)/2 + ...
%     sum( (rho_SSL.*transpose(C_dp_ext_components).*pi.*((d_ext_store./2).^2).*V_f_per_coax.^3)./2 );
P_parasite_equip = 0.5*rho_SSL*f_equip*V_f^3;
P_paraiste_clean = 0.5*rho_SSL*f_clean*V_f^3;
P_parasite = 0.5*rho_SSL*f_total*V_f^3;

% Aerodynamic shaft-power demand of BOTH main rotors.
P_rotors = k_int_lower_rotor_in_fullwake*P_induced + P_profile;

% Shaft power required by the pusher.
P_pusher_shaft_required = P_parasite / eta_prop;

% Engine power before the retained miscellaneous allowance.
Pf_minus_Pm = P_rotors + P_pusher_shaft_required / eta_drive;

% 15% misc allowance for now.
Pf = Pf_minus_Pm * (1 + misc_power); % total power

% %% Stage 8: Rear Prop Sizing
% V_max = V_f;
% r_min = 0.5;
% r_max = 2;
% 
% % Verify that this is the shaft power available to the propeller
% 
% P_avail = P_i-2*(P_induced_per_coax - P_profile_per_coax - misc_power*Pf_coax_minus_Pm);
% drag = (P_induced_per_coax*num_rotors) / V_f;
% 
% assert(V_max > 0 && P_avail > 0 && rho_SSL > 0, ...
%     'Speed, available power and density must be positive.');
% 
% r_range = r_min:0.2:r_max;
% 
% % The original range ends at 1.9 m; include 2 m explicitly
% if r_range(end) < r_max
%     r_range(end+1) = r_max;
% end
% 
% T_log = zeros(size(r_range));
% 
% for i = 1:numel(r_range)
%     r_prop = r_range(i);
% 
%     w = @(T) 0.5*(sqrt(V_max^2 + ...
%         2*T/(pi*r_prop^2*rho_SSL)) - V_max);
% 
%     residual = @(T) T*(V_max + w(T)) - P_avail;
% 
%     % Since w >= 0, thrust cannot exceed P_avail/V_max
%     T_log(i) = fzero(residual, [0, P_avail/V_max]);
% end
% 
% fprintf('Drag: %.1f N\n', drag);
% fprintf('Available propeller shaft power: %.1f W\n', P_avail);
% fprintf('Drag times speed: %.1f W\n', drag*V_max);
% fprintf('Ideal thrust upper bound: %.1f N\n', P_avail/V_max);
% 
% figure(2)
% clf
% % plot(r_range, T_log, 'LineWidth', 1.5)
% hold on
% yline(drag, '--', 'Required thrust')
% xlabel('Propeller radius (m)')
% ylabel('Thrust (N)')
% grid on
% hold off

%% Stage 8: Rear pusher propeller sizing
% Question answered: at forward speed V, with the power left over after the
% rotors have taken what they need, how much thrust can a pusher propeller of
% a given size produce, and is that enough to overcome the aircraft drag?
%
% Assumes Stage 7 has already run, using the per-coax convention:
%   P_induced, P_profile, P_parasite  are per coax unit [W]
%   num_coax                           number of coax stacks
%   V_f                       forward speed [m/s]



% ---------------- Power balance ----------------
% With a pusher carrying the propulsive load, the rotors only need to supply
% induced + profile power (plus the same loss factors used in Stage 7).
% Parasite power is deliberately left out: the propeller overcomes drag.

% Remove the aggregate allowance, then deduct main-rotor demand.
P_available_before_pusher_drive = ...
    P_installed_total / (1 + misc_power) - P_rotors;

% Actual shaft power available after the rear-drive loss.
P_avail = eta_drive * P_available_before_pusher_drive;

% Ideal actuator-disk calculation: all shaft power enters the ideal flow.
P_prop = P_avail;

% ---------------- Required thrust ----------------
% Parasite power = drag * speed, so drag = parasite power / speed
drag = P_parasite / V;         % [N]

assert(V > 0 && rho_SSL > 0, 'Speed and density must be positive.');
assert(P_avail > 0, ['No power left for the propeller: installed %.0f W, ' ...
    'rotors need %.0f W.'], P_installed_total, P_rotors);

% ---------------- Sweep propeller diameter ----------------
% Actuator-disk (momentum) theory for a propeller at forward speed V:
%   thrust            T = 2*rho*A*u*(u - V)     (u = air speed through the disk)
%   power into flow   P = T*u
% Combining gives a cubic in u:  u^3 - V*u^2 - P/(2*rho*A) = 0
% Take the one real root above V, then T = P/u.
d_range = linspace(d_min, d_max, n_points);
T_avail = zeros(size(d_range));

for i = 1:numel(d_range)
    A_prop = pi*(d_range(i)/2)^2;
    prop_cubic_k = P_prop/(2*rho_SSL*A_prop);
    c = roots([1, -V, 0, -prop_cubic_k]);
    u      = max(real(c(abs(imag(c)) < 1e-9)));   % real root (always > V)
    T_avail(i) = P_prop/u;
end

% ---------------- Smallest propeller that meets the drag ----------------
idx = find(T_avail >= drag, 1, 'first');

fprintf('Forward speed:                  %.1f m/s\n', V);
fprintf('Aircraft drag (required thrust): %.1f N\n', drag);
fprintf('Drag x speed:                   %.1f W\n', drag*V);
fprintf('Power left for propeller shaft: %.1f W\n', P_avail);
fprintf('Ideal thrust upper bound:       %.1f N  (= P_prop/V)\n', P_prop/V);
if isempty(idx)
    fprintf('No diameter in %.1f-%.1f m produces enough thrust.\n', d_min, d_max);
else
    fprintf('Smallest diameter that works:   %.2f m\n', d_range(idx));
end

% ---------------- Plot ----------------
figure(2); clf; hold on
plot(d_range, T_avail, 'LineWidth', 1.5, 'DisplayName', 'Available thrust')
yline(drag, '--', 'Required thrust (drag)', 'LineWidth', 1.2, 'HandleVisibility', 'off')
if ~isempty(idx)
    xline(d_range(idx), ':', sprintf('%.2f m', d_range(idx)), 'HandleVisibility', 'off')
end
xlabel('Propeller diameter (m)')
ylabel('Thrust (N)')
title(sprintf('Pusher propeller thrust at %.0f m/s', V))
legend('Location', 'southeast')
grid on
hold off

%% Refinement and Iteration: 

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
% fprintf('Maximum allowable tip speed: %.6g m/s\n',V_T);
fprintf('Forward velocity: %.6g m/s\n',V_f);
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
fprintf('Individual Rotor area: %.6g m^2\n',A_D_per_coax);
fprintf('Individal Rotor radius: %.6g m\n',R_per_coax);
fprintf('Number of blades per rotor: %.6g \n',b_per_coax_actual);
% fprintf('Number of Blades: %.6g\n',G);
fprintf('Rotor angular velocity (each): %.6g rad/s\n',omega_per_coax);
% fprintf('Forward velocity: %.6g m/s\n',V_f_per_coax);
fprintf('Tip Speed: %.6g m/s\n',V_T_coax);
fprintf('Blade chord per coax blade: %.6g m\n',c_per_coax_actual);
fprintf('Total clean parasitic drag coefficient: %.6g\n',C_dp_clean);
fprintf('Thrust coefficient: %.6g\n',C_T);
fprintf('Profile drag coefficient: %.6g\n',C_d0);
fprintf('Total Induced power per: %.6g W\n',P_induced);
fprintf('Total Profile power: %.6g W\n',P_profile);
fprintf('Total Parasite power: %.6g W\n',P_parasite);
fprintf('Total forward-flight power required: %.6g kW\n',Pf/1000);
fprintf('Power available to rear pusher: %.6g kW\n',P_avail/1000);

