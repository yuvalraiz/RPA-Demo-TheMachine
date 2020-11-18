namespace: YuvalRaiz.TheMachine.internal
flow:
  name: Machine_update_parts_level
  inputs:
    - machine_id
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
          - SUCCESS: get_all_parts_level
          - FAILURE: on_failure
    - get_all_parts_level:
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
            - command: "${'''select part_id, last_update, quantity  from public.machine_parts_current_level where machine_id = '%s' ''' % (machine_id)}"
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - all_data: '${return_result}'
        navigate:
          - SUCCESS: opcmon
          - FAILURE: on_failure
    - opcmon:
        parallel_loop:
          for: "part_data in all_data.split(';')"
          do:
            YuvalRaiz.TheMachine.internal.opcmon:
              - machine_id: '${machine_id}'
              - ci: "${'%s_part_%s' % (machine_id,part_data.split(',')[0])}"
              - node: "${'%s_part_%s' % (machine_id,part_data.split(',')[0])}"
              - obj_value_pairs: "${'productivity_quantity=%s' % (part_data.split(',')[2])}"
        navigate:
          - FAILURE: on_failure
          - SUCCESS: send_station_Cycle_to_bvd
    - send_station_Cycle_to_bvd:
        parallel_loop:
          for: "part_data in all_data.split(';')"
          do:
            io.cloudslang.base.http.http_client_post:
              - url: "${'''%s/bvd-receiver/api/submit/%s/tags/machine_part_level/dims/viewName,ciName''' % (bvd_url,bvd_api_key)}"
              - trust_all_roots: 'true'
              - request_character_set: utf-8
              - body: "${'''{\"viewName\": \"%s\", \"ciName\": \"%s\", \"quantity\": \"%s\"}''' % (machine_id, '%s_part_%s' % (machine_id,part_data.split(',')[0]), part_data.split(',')[2])}"
              - content_type: application/json
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_time:
        x: 59
        'y': 134
      get_all_parts_level:
        x: 191
        'y': 132
      opcmon:
        x: 342
        'y': 130
      send_station_Cycle_to_bvd:
        x: 485
        'y': 133
        navigate:
          e0ff25a0-20d2-274d-c16c-e159fcdfd00b:
            targetId: 9a2a8601-81d7-a355-d9ec-8405c5d0c786
            port: SUCCESS
          5c3d4ae9-3768-553d-d20e-cfe2d92deb28:
            targetId: 9a2a8601-81d7-a355-d9ec-8405c5d0c786
            port: FAILURE
    results:
      SUCCESS:
        9a2a8601-81d7-a355-d9ec-8405c5d0c786:
          x: 648
          'y': 134
