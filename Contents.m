%+UTILS Miscellaneous utility package that can be helpful at NML.
%
% Filtering Functions
%   add_sd_threshold                   - Adds yline threshold to plot using pre-stimulus data
%   apply_emg_filters                  - Apply filtering to EMG signal in data struct x.
%   get_default_filtering_pars         - Return default filtering parameters struct.
%
% Math
%   interpsmooth                       - This function interpolates and smoothes a curve onto data points
%   NEO                                - Returns the nonlinear energy operator (NEO) for signal X
%   SNEO                               - Returns the smoothed nonlinear energy operator (SNEO) for signal X
%
% Parsers
%   parse_date_args                    - Parse date input arguments
%   parse_bit_sync                     - Outputs a vector of trigger events that match up with the bit value from sync_bit. Accepts either a struct or vector
%   parse_parameters                   - Parses input parameters given a default struct.
%   parse_polybench_data_manager_notes - Parse notes taken in Polybench Data Manager.
%   parse_xml                          - Convert XML file to a MATLAB structure.
%   parameters                         - Return parameters struct, which sets default values for things like epoch durations etc.
%
% Handling NML Data Structures
%   apply_debounce                     - Debounce vector of sample times so that each is separated by *at least* `min_sample_interval` samples.
%   get_block_name                     - Return the string info corresponding to a given block
%   print_timing_info                  - Prints total time for a given function to run.
%   print_windows_folder_link          - Print or return string to link to windows folder(s)
%   sba_patch_2_struct                 - Convenience function to convert patch handle to struct
%   showModelInfo                      - Print model info and optionally make figure for covariances
