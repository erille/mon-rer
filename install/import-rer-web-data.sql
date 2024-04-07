\copy transco_icar from 'install/transcodification.csv' (format csv, header, delimiter ';')
\copy station_codes from 'install/station_codes.csv' (format csv, header)
\copy station_names from 'install/station_names.csv' (format csv, header)
\copy station_lines from 'install/station_lines.csv' (format csv, header)
