namespace: YuvalRaiz.TheMachine.internal
flow:
  name: update_bvd_with_power
  inputs:
    - bvd_url: "${get_sp('YuvalRaiz.TheMachine.bvd_url')}"
    - api_key: "${get_sp('YuvalRaiz.TheMachine.api_key')}"
  workflow:
    - get_last_tz:
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
            - command: "${'''select l.tz, r.power from (select tz from public.inventory where part_id = '1' order by tz desc limit 1) as l left join public.machine_general as r on true '''}"
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - tz: "${return_result.split(',')[0]}"
          - power: "${'on' if return_result.split(',')[1] =='t' else 'off'}"
        navigate:
          - SUCCESS: send_last_run_tz
          - FAILURE: on_failure
    - send_last_run_tz:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/assembly_warehouse,overall''' % (bvd_url,api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: |-
                ${'''{"lastrun": "%s",
                "power": "%s"
                }''' % (tz,power)}
            - content_type: application/json
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      send_last_run_tz:
        x: 291
        'y': 129
        navigate:
          bd3ad0ff-789c-f780-4407-3e0265e4a865:
            targetId: e4fec520-ae1b-3d2b-caa7-6bad0cb4bed9
            port: SUCCESS
      get_last_tz:
        x: 94
        'y': 121
    results:
      SUCCESS:
        e4fec520-ae1b-3d2b-caa7-6bad0cb4bed9:
          x: 481
          'y': 123
