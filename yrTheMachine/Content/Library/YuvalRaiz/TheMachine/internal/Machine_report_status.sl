namespace: YuvalRaiz.TheMachine.internal
flow:
  name: Machine_report_status
  inputs:
    - machine_id
    - control_name
    - control_hostname
    - power
    - bvd_url
    - bvd_api_key
  workflow:
    - opcmsg:
        do:
          YuvalRaiz.TheMachine.internal.opcmsg:
            - machine_id: '${machine_id}'
            - ci: '${control_name}'
            - node: '${control_hostname}'
            - eti: Productivity_Availability
            - sev: "${'Critical' if power == 'off' else 'Normal'}"
            - msg: "${'''Machine power is %s''' % (power)}"
        navigate:
          - FAILURE: on_failure
          - SUCCESS: get_machine_current_data
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
            - command: "${'''select max(tz) from public.parts_inventory where machine_id = '%s';''' % (machine_id)}"
            - trust_all_roots: 'true'
            - key: machine_id
        publish:
          - tz: '${return_result}'
        navigate:
          - HAS_MORE: send_machine_status_to_bvd
          - NO_MORE: send_machine_status_to_bvd
          - FAILURE: on_failure
    - send_machine_status_to_bvd:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/machine_state/dims/viewName''' % (bvd_url,bvd_api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: "${'''{\"viewName\": \"%s\", \"power\": \"%s\", \"last_run\": \"%s\"}''' %(machine_id,power,tz)}"
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
      opcmsg:
        x: 100
        'y': 150
      get_machine_current_data:
        x: 400
        'y': 150
      send_machine_status_to_bvd:
        x: 700
        'y': 150
        navigate:
          b8c03ad8-69a3-50c9-99dc-2c73452a5dde:
            targetId: d326f20e-fd5d-e4a4-0624-7e9a6ade7c2e
            port: SUCCESS
          0f6908e7-613a-7118-0d23-a9db7d9a8609:
            targetId: d326f20e-fd5d-e4a4-0624-7e9a6ade7c2e
            port: FAILURE
    results:
      SUCCESS:
        d326f20e-fd5d-e4a4-0624-7e9a6ade7c2e:
          x: 1000
          'y': 150
