namespace: YuvalRaiz.TheMachine.internal
flow:
  name: update_bvd_with_shipments
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
            - command: "${'''select sum(income) as money, count(income) as times from public.income where date_trunc('day',tz) = date_trunc('day',now())'''}"
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - money: "${return_result.split(',')[0]}"
          - times: "${'on' if return_result.split(',')[1] =='t' else 'off'}"
        navigate:
          - SUCCESS: send_to_bvd
          - FAILURE: on_failure
    - send_to_bvd:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/assembly_warehouse,shipment''' % (bvd_url,api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: |-
                ${'''{"moeny": "%s",
                "shipments": "%s"
                }''' % (money,times)}
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
      get_last_tz:
        x: 94
        'y': 121
      send_to_bvd:
        x: 291
        'y': 129
        navigate:
          bd3ad0ff-789c-f780-4407-3e0265e4a865:
            targetId: e4fec520-ae1b-3d2b-caa7-6bad0cb4bed9
            port: SUCCESS
    results:
      SUCCESS:
        e4fec520-ae1b-3d2b-caa7-6bad0cb4bed9:
          x: 481
          'y': 123
