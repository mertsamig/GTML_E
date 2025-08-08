classdef test_interpolation < matlab.unittest.TestCase
    % Test class for the interpolation utility functions.

    properties
        % Define a common, simple data set for use in multiple tests
        x_vec = [10, 20, 30, 40, 50];
        y_vec = [100, 200, 300, 400, 500];
    end

    methods (Test)

        function testFindPos(testCase)
            % Test the FindPos function to ensure it finds the correct lower index.

            % Test in the middle of an interval
            testCase.verifyEqual(FindPos(testCase.x_vec, 25), 2);

            % Test exactly on a grid point
            testCase.verifyEqual(FindPos(testCase.x_vec, 30), 3);

            % Test below the lower bound
            testCase.verifyEqual(FindPos(testCase.x_vec, 5), 1);

            % Test above the upper bound
            testCase.verifyEqual(FindPos(testCase.x_vec, 55), 4);
        end

        function testInterpolation(testCase)
            % Test the Interpolation function for correctness.

            % Test halfway between two points
            interp_val = Interpolation(testCase.x_vec, testCase.y_vec, 15);
            testCase.verifyEqual(interp_val, 150, 'AbsTol', 1e-9);

            % Test exactly on a grid point
            interp_val = Interpolation(testCase.x_vec, testCase.y_vec, 40);
            testCase.verifyEqual(interp_val, 400, 'AbsTol', 1e-9);

            % Test on a non-even fraction
            interp_val = Interpolation(testCase.x_vec, testCase.y_vec, 32);
            testCase.verifyEqual(interp_val, 320, 'AbsTol', 1e-9);
        end

        function testInterpolationEdgeCases(testCase)
            % Test that the interpolation function correctly handles inputs
            % outside the bounds of the data (it should extrapolate linearly).

            % Test below the lower bound
            interp_val = Interpolation(testCase.x_vec, testCase.y_vec, 5);
            testCase.verifyEqual(interp_val, 50, 'AbsTol', 1e-9, ...
                'Extrapolation below lower bound is incorrect.');

            % Test above the upper bound
            interp_val = Interpolation(testCase.x_vec, testCase.y_vec, 60);
            testCase.verifyEqual(interp_val, 600, 'AbsTol', 1e-9, ...
                'Extrapolation above upper bound is incorrect.');
        end

    end
end
