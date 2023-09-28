%+UTILS Miscellaneous utility package that can be helpful at NML.
%
% Filtering Functions
%   add_sd_threshold                   - Adds yline threshold to plot using pre-stimulus data
%   apply_emg_filters                  - Apply filtering to EMG signal in data struct x.
%   get_default_filtering_pars         - Return default filtering parameters struct.
%   get_filtering_label_string         - Returns string to indicate what filtering was done.
%   ordered_emg_filters                - Apply filtering to EMG signal in data struct x according to a specific order of operations.
%
% Math
%   interpsmooth                       - This function interpolates and smoothes a curve onto data points
%   NEO                                - Returns the nonlinear energy operator (NEO) for signal X
%   SNEO                               - Returns the smoothed nonlinear energy operator (SNEO) for signal X
%
% Parsers
%   tmsi_folder_2_datetime             - Convert TMSi folder timestring to datetime
%   tmsi_header_2_datetime             - Convert TMSi header start_time field to datetime
%   parse_artifact_sync                - Outputs a vector of trigger events that match up with logic parsed from a threshold set under the assumption that the input is a vector with large stimulus-related artifacts in it.
%   parse_date_args                    - Parse date input arguments
%   parse_bit_sync                     - Outputs a vector of trigger events that match up with the bit value from sync_bit. Accepts either a struct or vector
%   parse_parameters                   - Parses input parameters given a default struct.
%   parse_polybench_data_manager_notes - Parse notes taken in Polybench Data Manager.
%   parse_uevt_trials                  - Parse table from io.load_uevt, identifying trial metadata
%   parse_xml                          - Convert XML file to a MATLAB structure.
%   parse_xy_grid_vec                  - Parses xy grid to encapsulate values in x and values in y
%   parameters                         - Return parameters struct, which sets default values for things like epoch durations etc.
%
% Handling NML Data Structures
%   apply_debounce                     - Debounce vector of sample times so that each is separated by *at least* `min_sample_interval` samples.
%   export_emg_for_muedit              - export_emg_for_muedit(data, fsamp, nChan, ngrid, gridname, muscle) Exports matfile for MUedit app. 
%   generate_output_container_folder   - Generate output folder (windows-like) path-string.
%   get_block_name                     - Return the string info corresponding to a given block
%   get_subj_query                     - Return the subject-info args for most "load" and "plot" queries, given the subject query struct.
%   print_timing_info                  - Prints total time for a given function to run.
%   print_windows_folder_link          - Print or return string to link to windows folder(s)
%   transfer_plexon_files              - Transfer files from local location to remote data share
%   patch_2_struct                     - Convenience function to convert patch handle to struct
%
% Typesetting and Formatting Text
%   showModelInfo                      - Print model info and optionally make figure for covariances
%   contents_report_2_markdown         - Convert Contents.m MATLAB index file into formatted Contents for README.md
%   fixCase                            - Fixes the input string so first character in string is capitalized and rest are lower-case.
%   get_tmsi_stim_data                 - Return stim data specifically for TMSi blocks
%   print_model_info                   - Prints sfit object model coefficients in Command Window, or to a text file ID (if specified).
%   pattern_name_to_metadata           - Helper function to convert pattern files to metadata struct
%   save_figure                        - Exports figure in desired file formats, creating output folder if needed.
