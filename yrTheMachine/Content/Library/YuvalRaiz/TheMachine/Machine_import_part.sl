namespace: YuvalRaiz.TheMachine
flow:
  name: Machine_import_part
  inputs:
    - machine_id
    - part_id
    - quantity
  workflow:
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: update_inventory
          - FAILURE: on_failure
    - Machine_update_parts_level:
        do:
          YuvalRaiz.TheMachine.internal.Machine_update_parts_level:
            - machine_id: '${machine_id}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
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
                values ('%s','%s', '%s'::TIMESTAMP, %s, 'shipment');''' % (machine_id,part_id, tz, quantity)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: Machine_update_parts_level
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      Machine_update_parts_level:
        x: 365
        'y': 140
        navigate:
          4a5ff163-eb94-8738-0c1c-027a29249cc5:
            targetId: 43158961-3797-12f6-263b-5d210075db37
            port: SUCCESS
      update_inventory:
        x: 211
        'y': 138
      get_time:
        x: 79
        'y': 136
    results:
      SUCCESS:
        43158961-3797-12f6-263b-5d210075db37:
          x: 540
          'y': 136
