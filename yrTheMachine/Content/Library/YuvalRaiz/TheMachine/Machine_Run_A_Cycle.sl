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
          - SUCCESS: Machine_update_parts_level
    - Machine_update_parts_level:
        do:
          YuvalRaiz.TheMachine.internal.Machine_update_parts_level:
            - machine_id: '${machine_id}'
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
        x: 100
        'y': 350
      is_machine_power:
        x: 400
        'y': 350
      get_all_stations:
        x: 700
        'y': 175
      Station_Run_A_Cycle:
        x: 998
        'y': 174
      Machine_report_status:
        x: 700
        'y': 525
      is_machine_power_1:
        x: 1000
        'y': 525
        navigate:
          583c5668-11b6-328f-1041-cc6fbaac8db9:
            targetId: 159c707c-4141-6694-5128-ab00218d5e3f
            port: 'TRUE'
          f1ae5233-e74c-8573-79bd-a3d73c271d26:
            targetId: 0022ebc8-9ac4-02f7-3c63-1689c3f9b5f3
            port: 'FALSE'
      Machine_Consume_Outcomes:
        x: 1300
        'y': 116.66666666666667
      Machine_update_parts_level:
        x: 931
        'y': 390
    results:
      SUCCESS:
        159c707c-4141-6694-5128-ab00218d5e3f:
          x: 1300
          'y': 350
      Machine_PowerOff:
        0022ebc8-9ac4-02f7-3c63-1689c3f9b5f3:
          x: 1300
          'y': 583.3333333333334
