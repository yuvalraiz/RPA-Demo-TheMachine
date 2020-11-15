namespace: YuvalRaiz.TheMachine
flow:
  name: Machine_Run_A_Cycle
  inputs:
    - machine_id
    - bvd_url: "${get_sp('YuvalRaiz.TheMachine.bvd_url')}"
    - bvd_api_key: "${get_sp('YuvalRaiz.TheMachine.bvd_api_key')}"
  workflow:
    - get_machine_current_data:
        do:
          io.cloudslang.base.database.sql_query:
            - db_server_name: "${get_sp('YuvalRaiz.TheMachine.db_hostname')}"
            - db_type: PostgreSQL
            - username: "${get_sp('YuvalRaiz.TheMachine.db_username')}"
            - password:
                value: "${get_sp('YuvalRaiz.TheMachine.db_password')}"
                sensitive: true
            - database_name: "${get_sp('YuvalRaiz.TheMachine.db_name')}"
            - db_url: "${'''jdbc:postgresql://%s:5432/%s''' % (db_server_name,database_name)}"
            - command: "${'''select outcome_price,shipment_size,control_name,control_hostname,power from public.Machine_Current_Configuration where machine_id = '%s';''' % (machine_id)}"
            - trust_all_roots: 'true'
            - key: machine_id
        publish:
          - outcome_price: "${return_result.split(',')[0][1:-3]}"
          - shipment_size: "${return_result.split(',')[1]}"
          - control_name: "${return_result.split(',')[2]}"
          - control_hostname: "${return_result.split(',')[3]}"
          - power: "${return_result.split(',')[4]}"
        navigate:
          - HAS_MORE: is_machine_power
          - NO_MORE: is_machine_power
          - FAILURE: on_failure
    - is_machine_power:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: "${str(power=='on')}"
        navigate:
          - 'TRUE': get_all_stations
          - 'FALSE': Machine_report_status
    - get_all_stations:
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
            - command: "${'''select station_id, station_name, station_hostname from public.station_current_configuration where machine_id = '%s' ''' % (machine_id)}"
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - all_stations: '${return_result}'
        navigate:
          - SUCCESS: Station_Run_A_Cycle
          - FAILURE: on_failure
    - Station_Run_A_Cycle:
        parallel_loop:
          for: "station_data in all_stations.split(';')"
          do:
            YuvalRaiz.TheMachine.internal.Station_Run_A_Cycle:
              - machine_id: '${machine_id}'
              - station_id: "${station_data.split(',')[0]}"
              - bvd_url: '${bvd_url}'
              - bvd_api_key: '${bvd_api_key}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: Machine_Consume_Outcomes
    - Machine_report_status:
        do:
          YuvalRaiz.TheMachine.internal.Machine_report_status:
            - machine_id: '${machine_id}'
            - control_name: '${control_name}'
            - control_hostname: '${control_hostname}'
            - power: '${power}'
            - bvd_url: '${bvd_url}'
            - bvd_api_key: '${bvd_api_key}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: is_machine_power_1
    - is_machine_power_1:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: "${str(power=='on')}"
        navigate:
          - 'TRUE': SUCCESS
          - 'FALSE': Machine_PowerOff
    - Machine_Consume_Outcomes:
        do:
          YuvalRaiz.TheMachine.internal.Machine_Consume_Outcomes:
            - machine_id: '${machine_id}'
            - shipment_size: '${shipment_size}'
            - outcome_price: '${outcome_price}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: Machine_report_status
  results:
    - FAILURE
    - SUCCESS
    - Machine_PowerOff
extensions:
  graph:
    steps:
      get_machine_current_data:
        x: 58
        'y': 109
      is_machine_power:
        x: 218
        'y': 105
      get_all_stations:
        x: 365
        'y': 104
      Station_Run_A_Cycle:
        x: 511
        'y': 105
      Machine_report_status:
        x: 611
        'y': 278
      is_machine_power_1:
        x: 819
        'y': 483
        navigate:
          da42ae95-6d40-013f-d9dd-dbac8342e5e6:
            targetId: 04d51ea4-1000-61c9-2988-44ea34cd12de
            port: 'FALSE'
          ca98a51a-f8e2-dcac-117a-4cf0f28db403:
            targetId: 1f878711-094f-f59c-838d-27aaec03730d
            port: 'TRUE'
      Machine_Consume_Outcomes:
        x: 702
        'y': 111
    results:
      SUCCESS:
        1f878711-094f-f59c-838d-27aaec03730d:
          x: 995
          'y': 426
      Machine_PowerOff:
        04d51ea4-1000-61c9-2988-44ea34cd12de:
          x: 939
          'y': 570
