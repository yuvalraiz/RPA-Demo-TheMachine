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
            - command: "${'''select max(tz) from public.machine_part_inventory where machine_id = '%s';''' % (machine_id)}"
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
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/machine_state/dims/machine_id''' % (bvd_url,bvd_api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: "${'''{\"machine_id\": \"%s\", \"power\": \"%s\", \"last_run\": \"%s\"}''' %(machine_id,power,tz)}"
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
      opcmsg:
        x: 43
        'y': 110
      get_machine_current_data:
        x: 175
        'y': 112
      send_machine_status_to_bvd:
        x: 326
        'y': 114
        navigate:
          605992c6-c9f1-4b29-d732-730d29f7a5fb:
            targetId: 465b2af9-9261-620a-f758-b93238f4bf07
            port: SUCCESS
    results:
      SUCCESS:
        465b2af9-9261-620a-f758-b93238f4bf07:
          x: 477
          'y': 115
