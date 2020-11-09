namespace: YuvalRaiz.TheMachine.internal
flow:
  name: update_bvd_with_warehouse
  inputs:
    - bvd_url: "${get_sp('YuvalRaiz.TheMachine.bvd_url')}"
    - api_key: "${get_sp('YuvalRaiz.TheMachine.api_key')}"
  workflow:
    - get_all_parts_ids:
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
                select station_name, current_quantity from (select station_name, station_id from public.machine_setup
                union ALL select 'inputs', '0') as l
                left join (select sum(quantity) as current_quantity, part_id from public.inventory group by part_id) as r
                 on station_id = part_id
                '''}
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - all_data: '${return_result}'
        navigate:
          - SUCCESS: send_to_bvd
          - FAILURE: on_failure
    - send_to_bvd:
        loop:
          for: "station_data in all_data.split(';')"
          do:
            io.cloudslang.base.http.http_client_post:
              - url: "${'''%s/bvd-receiver/api/submit/%s/dims/ciName/tags/assembly_warehouse''' % (bvd_url,api_key)}"
              - trust_all_roots: 'true'
              - request_character_set: utf-8
              - body: |-
                  ${'''{
                      "ciName": "%s",
                      "ready_parts": "%s"
                  }''' % (station_data.split(',')[0], station_data.split(',')[1])}
              - content_type: application/json
          break:
            - FAILURE
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      send_to_bvd:
        x: 317
        'y': 131
        navigate:
          625b85ca-a702-96a6-599f-7092ed78bbdf:
            targetId: e4fec520-ae1b-3d2b-caa7-6bad0cb4bed9
            port: SUCCESS
      get_all_parts_ids:
        x: 169
        'y': 126
    results:
      SUCCESS:
        e4fec520-ae1b-3d2b-caa7-6bad0cb4bed9:
          x: 481
          'y': 123
