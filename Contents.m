%+UTILS Miscellaneous utility package that can be helpful at NML.
%
% Filtering Functions
%   add_sd_threshold                        - Adds yline threshold to plot using pre-stimulus data
%   apply_emg_filters                       - Apply filtering to EMG signal in data struct x.
%   get_block_pattern                       - Return the string corresponding to a given block
%   get_default_filtering_pars              - Return default filtering parameters struct.
%
% Math
%   interpsmooth                            - This function interpolates and smoothes a curve onto data points
%   NEO                                     - Returns the nonlinear energy operator (NEO) for signal X
%   SNEO                                    - Returns the smoothed nonlinear energy operator (SNEO) for signal X
%
% Parsers
%   parse_date_args                         - Parse date input arguments
%   parse_bit_sync                          - Outputs a vector of trigger events that match up with the bit value from sync_bit. Accepts either a struct or vector
%   parse_parameters                        - Parses input parameters given a default struct.
%   parse_polybench_data_manager_notes      - Parse notes taken in Polybench Data Manager.
%   parse_xml                               - Convert XML file to a MATLAB structure.
