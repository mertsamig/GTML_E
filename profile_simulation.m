% This script runs a simplified, open-loop simulation of a turbojet engine
% for the purpose of performance profiling.

% Get the path to the directory containing this script
[rootDir, ~, ~] = fileparts(mfilename('fullpath'));

% Add the foundation and components directories to the path
addpath(genpath(fullfile(rootDir, 'foundation')));
addpath(genpath(fullfile(rootDir, 'components')));

% --- Start Profiling ---
profile on;

% --- Simulation Loop (for profiling) ---
% We'll run the calculations multiple times to get a good sample for the profiler.
for i = 1:100

% --- Define Inputs and Constants ---

% Gas Path Characterization Vector: [Mass Flow (kg/s), Enthalpy (J/kg), Total Temp (K), Total Press (Pa), FAR]
GasPthChar_In = [ 20, 0, 288, 101325, 0 ]; % Initial conditions (e.g., at engine inlet)

% Component-specific inputs (using plausible example values)
CNST = [101325, 288]; % [PSTD, TSTD]
Nmech = 10000; % Mechanical speed (rpm)

% Compressor Inputs
beta_comp = 0;
VSV = 0;
% Dummy map data (tables of numbers)
comp_map_dummy = ones(10, 10);
SF_comp = [1, 1, 1];
% For simplicity, we'll ignore bleeds for this test
CustBldsPlan = [];
FBldsPlan = [];
WcSurgeVec = [];
PRSurgeVec = [];

% Burner Inputs
dpbur = 0.05; % Pressure drop
LHV = 43e6; % Lower Heating Value (Jet Fuel)
Eff_des_burn = 0.98;
PtIn_des_burn = 10e5;
TtIn_des_burn = 500;
WIn_des_burn = 20;
TtIn_fuel = 288;
Wfin = 0.5; % Fuel flow
FuelType = 1; % Oil
Load_tab_burn = [0, 1]; Eff_tab_burn = [0.9, 1];
SF_burn = [1, 1];
FixEff_burn = 0;
Volume_burn = 0.1;

% Turbine Inputs
CoolingFlwCharIn_turb = []; % No cooling flow for simplicity
PRMap_turb = 2.5;
CoolingPlan_turb = [];
% Dummy map data
turb_map_dummy = ones(10, 10);
SF_turb = [1, 1, 1];

% Nozzle Inputs
PambIn_nozz = 101325; % Ambient pressure
AthroatIn_nozz = 0.1; % Throat area
Cdth_nozz = 0.98;
CV_nozz = 0.99;
CX_nozz = 0.99;


% --- Execute Component Chain ---

% 1. Compressor
[GasPthChar_CompOut, PwrComp, ~, ~, ~, ~, ~] = Compressor(GasPthChar_In, Nmech, beta_comp, VSV, CustBldsPlan, FBldsPlan, comp_map_dummy, comp_map_dummy, comp_map_dummy, comp_map_dummy, comp_map_dummy, SF_comp, CNST, WcSurgeVec, PRSurgeVec);

% 2. Burner
[GasPthChar_BurnOut, ~] = Burner(GasPthChar_CompOut, CNST, dpbur, LHV, Eff_des_burn, PtIn_des_burn, TtIn_des_burn, WIn_des_burn, TtIn_fuel, Wfin, FuelType, Load_tab_burn, Eff_tab_burn, SF_burn, FixEff_burn, Volume_burn);

% 3. Turbine
[GasPthChar_TurbOut, PwrTurb, ~, ~, ~] = Turbine(CoolingFlwCharIn_turb, GasPthChar_BurnOut, Nmech, PRMap_turb, CoolingPlan_turb, turb_map_dummy, turb_map_dummy, turb_map_dummy, turb_map_dummy, SF_turb, CNST, FuelType);

% 4. Nozzle
[~, FgOut, ~, ~, ~] = Nozzle(GasPthChar_TurbOut, PambIn_nozz, AthroatIn_nozz, Cdth_nozz, CV_nozz, CX_nozz);

end

% --- Stop Profiling and Show Results ---
profile viewer;

% To run this script:
% 1. Open MATLAB
% 2. Navigate to the root directory of this project
% 3. Run 'profile_simulation' in the MATLAB command window
disp('Profiling complete. Run "profile viewer" to see the results if they do not open automatically.');
