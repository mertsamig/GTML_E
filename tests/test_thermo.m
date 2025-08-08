classdef test_thermo < matlab.unittest.TestCase
    % Test class for the core thermodynamic functions in the foundation/ directory.

    methods (Test)

        function testAirProperties(testCase)
            % Test the properties of dry air (FAR=0) against a reference value.
            % Note: Reference values can vary based on the source and reference
            % state. This test uses a loose tolerance to confirm the values are
            % in a reasonable range.

            % Enthalpy difference between 1000K and 300K for air is ~745 kJ/kg
            H_1000 = H_T(1000, 0, 'Oil');
            H_300 = H_T(300, 0, 'Oil');
            h_diff_ref = 745.85e3; % J/kg

            testCase.verifyEqual(H_1000 - H_300, h_diff_ref, 'RelTol', 0.05, ...
                'Enthalpy difference for air is not within 5% of reference value.');

            % Specific heat of air at 300K is ~1.005 kJ/kg/K
            Cp_300 = Cp_T(300, 0, 'Oil');
            cp_ref = 1.005e3; % J/kg/K

            testCase.verifyEqual(Cp_300, cp_ref, 'RelTol', 0.05, ...
                'Specific heat for air is not within 5% of reference value.');
        end

        function testThermoRelationship(testCase)
            % Test that the thermodynamic relationship Cp = dH/dT holds.
            % We can test this by taking a numerical derivative of H_T and
            % comparing it to the value from Cp_T.

            T = 800; % Test at a mid-range temperature
            FAR = 0.02;

            % Calculate Cp directly
            Cp_direct = Cp_T(T, FAR, 'Oil');

            % Calculate Cp via numerical derivative of H
            delta_T = 0.1;
            H_plus = H_T(T + delta_T, FAR, 'Oil');
            H_minus = H_T(T - delta_T, FAR, 'Oil');
            Cp_numerical = (H_plus - H_minus) / (2 * delta_T);

            testCase.verifyEqual(Cp_direct, Cp_numerical, 'RelTol', 1e-4, ...
                'Numerical derivative of H_T does not match Cp_T.');
        end

        function testSolverRoundTrip_T_H(testCase)
            % Test that the T_H solver correctly inverts the H_T function.
            % T_H(H_T(T)) should equal T.

            T_original = 1234.5;
            FAR = 0.03;

            % Forward calculation
            H_val = H_T(T_original, FAR, 'Oil');

            % Inverse calculation (round-trip)
            T_roundtrip = T_H(H_val, FAR, T_original, 'Oil');

            testCase.verifyEqual(T_roundtrip, T_original, 'RelTol', 1e-6, ...
                'T_H solver failed the round-trip test.');
        end

        function testSolverRoundTrip_T_psi(testCase)
            % Test that the T_psi solver correctly inverts the psi_T function.
            % T_psi(psi_T(t)) should equal t.

            t_original = 987.6;
            f = 0.01;

            % Forward calculation
            psi_val = psi_T(t_original, f, 'Oil');

            % Inverse calculation (round-trip)
            t_roundtrip = T_psi(psi_val, f, t_original, 'Oil');

            testCase.verifyEqual(t_roundtrip, t_original, 'RelTol', 1e-6, ...
                'T_psi solver failed the round-trip test.');
        end

    end
end
