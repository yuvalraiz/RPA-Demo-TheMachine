namespace: YuvalRaiz.TheMachine.internal
flow:
  name: Station_Run_A_Cycle
  inputs:
    - machine_id
    - station_id
    - bvd_url: "${get_sp('YuvalRaiz.TheMachine.bvd_url')}"
    - bvd_api_key: "${get_sp('YuvalRaiz.TheMachine.bvd_api_key')}"
  workflow:
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: get_station_current_data
          - FAILURE: on_failure
    - get_station_current_data:
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
            - command: |-
                ${'''
                select station_name, station_hostname, max_production_in_cycle, inaccuracy, power, efficiency
                from station_current_configuration
                where machine_id = '%s' and station_id = '%s'; ''' % (machine_id, station_id)}
            - trust_all_roots: 'true'
            - key: machine_id
        publish:
          - station_name: "${return_result.split(',')[0]}"
          - station_hostname: "${return_result.split(',')[1]}"
          - max_production_in_cycle: "${return_result.split(',')[2]}"
          - inaccuracy: "${return_result.split(',')[3]}"
          - power: "${return_result.split(',')[4]}"
          - efficiency: "${return_result.split(',')[5]}"
        navigate:
          - HAS_MORE: get_station_input_status
          - NO_MORE: get_station_input_status
          - FAILURE: on_failure
    - get_station_input_status:
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
                ${'''
                select possible_assembly
                from station_posible_assembly_by_parts
                where machine_id = '%s' and station_id = '%s';
                ''' % (machine_id, station_id)}
            - trust_all_roots: 'true'
            - row_delimiter: ','
        publish:
          - possible_assembly: "${str(eval('min('+return_result+')')) if ',' in return_result else return_result}"
        navigate:
          - SUCCESS: station_actual_work
          - FAILURE: on_failure
    - station_actual_work:
        do:
          YuvalRaiz.TheMachine.internal.station_actual_work:
            - machine_id: '${machine_id}'
            - station_id: '${station_id}'
            - station_name: '${station_name}'
            - station_hostname: '${station_hostname}'
            - tz: '${tz}'
            - power: '${power}'
            - max_production_in_cycle: '${max_production_in_cycle}'
            - inaccuracy: '${inaccuracy}'
            - efficiency: '${efficiency}'
            - possible_assembly: '${possible_assembly}'
        publish:
          - created_items
          - try_assembly
          - productivity_level
          - ci
          - node
          - msg
          - eti
          - sev
          - obj_value_pairs
          - bvd_json
        navigate:
          - POWER_OFF: opcmsg
          - MISSING_PARTS: opcmsg
          - SUCCESS: update_inventory
    - opcmsg:
        do:
          YuvalRaiz.TheMachine.internal.opcmsg:
            - machine_id: '${machine_id}'
            - ci: '${ci}'
            - node: '${node}'
            - eti: '${eti}'
            - sev: '${sev}'
            - msg: '${msg}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: send_station_Cycle_to_bvd
    - opcmon:
        do:
          YuvalRaiz.TheMachine.internal.opcmon:
            - machine_id: '${machine_id}'
            - ci: '${ci}'
            - node: '${station_hostname}'
            - obj_value_pairs: '${obj_value_pairs}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: opcmsg
    - send_station_Cycle_to_bvd:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/station_cycle/dims/machine_id,station_name''' % (bvd_url,bvd_api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: '${bvd_json}'
            - content_type: application/json
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
    - update_inventory:
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
                ${'''insert into public.machine_part_inventory (machine_id,part_id,tz,quantity,src)
                (select machine_id, part_id, '%s', required_quantity * -%s,  station_id
                from public.station_requirements where machine_id = '%s' and station_id = '%s'
                union values ('%s','%s', '%s'::TIMESTAMP, %s, '%s')
                )
                ;''' % (tz, try_assembly, machine_id, station_id, machine_id,station_id, tz, created_items, station_id)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: opcmon
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_time:
        x: 56
        'y': 214
      get_station_current_data:
        x: 199
        'y': 216
      get_station_input_status:
        x: 329
        'y': 216
      station_actual_work:
        x: 477
        'y': 219
      opcmsg:
        x: 649
        'y': 214
      opcmon:
        x: 654
        'y': 362
      send_station_Cycle_to_bvd:
        x: 760
        'y': 218
        navigate:
          572dedf8-efcc-4a88-23a3-b5b09a842112:
            targetId: 1981ffd0-990c-459c-4b0f-96261d8de8f6
            port: SUCCESS
      update_inventory:
        x: 489
        'y': 367
    results:
      SUCCESS:
        1981ffd0-990c-459c-4b0f-96261d8de8f6:
          x: 974
          'y': 213
