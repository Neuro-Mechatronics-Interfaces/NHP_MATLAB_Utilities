# NHP_Matlab_Utilities #
**Note: this repo *must* be added as a submodule named +utils for most of the functions to work together properly.**
Matlab package containing miscellaneous utility functions such as file-transfer shortcuts or random math functions.  

## Install ##
You should be in the repository folder that is the parent repo of this submodule, which should be added as a MATLAB package (i.e. with the leading `+` in the name of the submodule folder). For example, add it to your workspace repository as:  
```(matlab)
git submodule add git@github.com:Neuro-Mechatronics-Interfaces/NHP_MATLAB_Utilities.git +utils
```
This will add the folder with the correct package name. **Adding +utils to the end of the `git submodule add` command is critical for making sure the functions work together properly.**

## Contents ##  
### Filtering Functions ###  
 + [add_sd_threshold](add_sd_threshold.m) - Adds yline threshold to plot using pre-stimulus data.  
 + [apply_emg_filters](apply_emg_filters.m) - Apply filtering to EMG signal in data struct x.  
 + [get_default_filtering_pars](get_default_filtering_pars.m) - Return default filtering parameters struct.  
 + [get_filtering_label_string](get_filtering_label_string.m) - Returns string to indicate what filtering was done.  
 + [ordered_emg_filters](ordered_emg_filters.m) - Apply filtering to EMG signal in data struct x according to a specific order of operations.  

### Math ###  
 + [interpsmooth](interpsmooth.m) - This function interpolates and smoothes a curve onto data points.  
 + [NEO](NEO.m) - Returns the nonlinear energy operator (NEO) for signal X.  
 + [SNEO](SNEO.m) - Returns the smoothed nonlinear energy operator (SNEO) for signal X.  

### Parsers ###  
 + [tmsi_folder_2_datetime](tmsi_folder_2_datetime.m) - Convert TMSi folder timestring to datetime.  
 + [tmsi_header_2_datetime](tmsi_header_2_datetime.m) - Convert TMSi header start_time field to datetime.  
 + [parse_artifact_sync](parse_artifact_sync.m) - Outputs a vector of trigger events that match up with logic parsed from a threshold set under the assumption that the input is a vector with large stimulus-related artifacts in it.  
 + [parse_date_args](parse_date_args.m) - Parse date input arguments.  
 + [parse_bit_sync](parse_bit_sync.m) - Outputs a vector of trigger events that match up with the bit value from sync_bit. Accepts either a struct or vector.  
 + [parse_parameters](parse_parameters.m) - Parses input parameters given a default struct.  
 + [parse_polybench_data_manager_notes](parse_polybench_data_manager_notes.m) - Parse notes taken in Polybench Data Manager.  
 + [parse_uevt_trials](parse_uevt_trials.m) - Parse table from io.load_uevt, identifying trial metadata.  
 + [parse_xml](parse_xml.m) - Convert XML file to a MATLAB structure.  
 + [parse_xy_grid_vec](parse_xy_grid_vec.m) - Parses xy grid to encapsulate values in x and values in y.  
 + [parameters](parameters.m) - Return parameters struct, which sets default values for things like epoch durations etc.  

### Handling NML Data Structures ###  
 + [apply_debounce](apply_debounce.m) - Debounce vector of sample times so that each is separated by *at least* `min_sample_interval` samples.  
 + [export_emg_for_muedit](export_emg_for_muedit.m) - export_emg_for_muedit(data, fsamp, nChan, ngrid, gridname, muscle) Exports matfile for MUedit app.  
 + [get_block_name](get_block_name.m) - Return the string info corresponding to a given block.  
 + [get_subj_query](get_subj_query.m) - Return the subject-info args for most "load" and "plot" queries, given the subject query struct.  
 + [print_timing_info](print_timing_info.m) - Prints total time for a given function to run.  
 + [print_windows_folder_link](print_windows_folder_link.m) - Print or return string to link to windows folder(s).  
 + [transfer_plexon_files](transfer_plexon_files.m) - Transfer files from local location to remote data share.  
 + [patch_2_struct](patch_2_struct.m) - Convenience function to convert patch handle to struct.  

### Typesetting and Formatting Text ###  
 + [showModelInfo](showModelInfo.m) - Print model info and optionally make figure for covariances.  
 + [contents_report_2_markdown](contents_report_2_markdown.m) - Convert Contents.m MATLAB index file into formatted Contents for README.md.  
 + [fixCase](fixCase.m) - Fixes the input string so first character in string is capitalized and rest are lower-case.  
 + [get_tmsi_stim_data](get_tmsi_stim_data.m) - Return stim data specifically for TMSi blocks.  
 + [print_model_info](print_model_info.m) - Prints sfit object model coefficients in Command Window, or to a text file ID (if specified).  
 + [pattern_name_to_metadata](pattern_name_to_metadata.m) - Helper function to convert pattern files to metadata struct.  
