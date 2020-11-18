########################################################################################################################
#!!
#! @input station_id_or_name: can be station name
#! @input power: on|off
#! @input efficiency: 0..100
#! @input istant_run: true|false (empty = true)
#!!#
########################################################################################################################
namespace: YuvalRaiz.TheMachine
flow:
  name: Station_Set_Runtime_Configuration
  inputs:
    - machine_id
    - station_id_or_name:
        required: true
    - power:
        default: 'on'
        required: false
    - efficiency:
        default: '100'
        required: false
    - istant_run:
        required: false
    - _invoke_cycle:
        default: "${get('istant_run','true')}"
        private: true
  workflow:
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: get_current_data
          - FAILURE: on_failure
    - update_station_configuration:
        do:
          io.cloudslang.base.database.sql_command:
            - db_server_name: "${get_sp('YuvalRaiz.TheMachine.db_hostname')}"
            - db_type: PostgreSQL
            - username: "${get_sp('YuvalRaiz.TheMachine.db_username')}"
            - password:
                value: "${get_sp('YuvalRaiz.TheMachine.db_password')}"
                sensitive: true
            - db_port: '5432'
            - database_name: "${get_sp('YuvalRaiz.TheMachine.db_name')}"
            - db_url: "${'''jdbc:postgresql://%s:5432/%s''' % (db_server_name,database_name)}"
            - command: |-
                ${'''insert into public.station_runtime_configuration (machine_id,station_id,tz,power,efficiency)
                values ('%s','%s','%s','%s',%s);''' % (machine_id,station_id,tz, current_power if power is None else 'off' if power == 'off' else 'on', current_efficiency if efficiency is None else efficiency )}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: should_invoke_cycle
          - FAILURE: on_failure
    - Machine_Run_A_Cycle:
        do:
          YuvalRaiz.TheMachine.Machine_Run_A_Cycle:
            - machine_id: '${machine_id}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
          - Machine_PowerOff: SUCCESS
    - should_invoke_cycle:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: "${str(_invoke_cycle=='true')}"
        navigate:
          - 'TRUE': Machine_Run_A_Cycle
          - 'FALSE': SUCCESS
    - get_current_data:
        do:
          io.cloudslang.base.database.sql_query_all_rows:
            - db_server_name: "${get_sp('YuvalRaiz.TheMachine.db_hostname')}"
            - db_type: PostgreSQL
            - username: "${get_sp('YuvalRaiz.TheMachine.db_username')}"
            - password:
                value: "${get_sp('YuvalRaiz.TheMachine.db_password')}"
                sensitive: true
            - db_port: '5432'
            - database_name: "${get_sp('YuvalRaiz.TheMachine.db_name')}"
            - command: |-
                ${'''select power,efficiency,station_id from public.station_current_configuration
                where machine_id = '%s' and (station_id = '%s'  or station_name = '%s' );  ''' % (machine_id,station_id_or_name, station_id_or_name)}
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - current_power: "${return_result.split(',')[0]}"
          - current_efficiency: "${return_result.split(',')[1]}"
          - station_id: "${return_result.split(',')[2]}"
        navigate:
          - SUCCESS: update_station_configuration
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_time:
        x: 100
        'y': 250
      update_station_configuration:
        x: 700
        'y': 250
      Machine_Run_A_Cycle:
        x: 1300
        'y': 125
        navigate:
          94564c1f-a232-663d-7571-6dd7bf079bd4:
            targetId: 4c6965f3-cdf7-4340-156d-2383d68ae0d7
            port: SUCCESS
          99916fdf-9cc5-1c4a-eb35-77aafb93458a:
            targetId: 4c6965f3-cdf7-4340-156d-2383d68ae0d7
            port: Machine_PowerOff
      should_invoke_cycle:
        x: 1000
        'y': 250
        navigate:
          44aae8dc-7cbd-edb6-24ab-6ba2efc17753:
            targetId: 4c6965f3-cdf7-4340-156d-2383d68ae0d7
            port: 'FALSE'
      get_current_data:
        x: 400
        'y': 250
    results:
      SUCCESS:
        4c6965f3-cdf7-4340-156d-2383d68ae0d7:
          x: 1300
          'y': 375
