namespace: YuvalRaiz.TheMachine.internal
flow:
  name: transfer_to_shop
  workflow:
    - get_shippment_params:
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
            - command: "${'''select current_price, min_shippment from public.machine_general where id = 1'''}"
            - trust_all_roots: 'true'
            - key: id
        publish:
          - current_price: "${return_result.split(',')[0][1:]}"
          - min_shippment: "${return_result.split(',')[1]}"
        navigate:
          - HAS_MORE: sql_query_all_rows
          - NO_MORE: sql_query_all_rows
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
                ${'''insert into public.inventory (tz,part_id,quantity) values
                ('%s','%s',-%s);''' % (tz,last_station,min_shippment)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: update_income
          - FAILURE: on_failure
    - ready_to_ship:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: '${str(int(left_items)>0)}'
        publish: []
        navigate:
          - 'TRUE': get_time
          - 'FALSE': SUCCESS
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: update_inventory
          - FAILURE: on_failure
    - sleep:
        do:
          io.cloudslang.base.utils.sleep:
            - seconds: '2'
        navigate:
          - SUCCESS: sql_query_all_rows
          - FAILURE: on_failure
    - update_income:
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
                ${'''insert into public.income (tz,income) values
                ('%s',%s);''' % (tz,int(min_shippment)*float(current_price))}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: sleep
          - FAILURE: on_failure
    - sql_query_all_rows:
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
            - db_url: "${'''jdbc:postgresql://%s:5432/%s''' % (db_server_name,database_name)}"
            - command: "${'''select sum(quantity),part_id from public.inventory  where part_id in (select station_id from public.machine_setup order by station_id desc limit 1) group by part_id;'''}"
            - trust_all_roots: 'true'
            - min_shippment: '${min_shippment}'
        publish:
          - ready_items: "${return_result.split(',')[0]}"
          - last_station: "${return_result.split(',')[1]}"
          - left_items: '${str(int(ready_items) - int(min_shippment))}'
        navigate:
          - SUCCESS: ready_to_ship
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_shippment_params:
        x: 34
        'y': 77
      update_inventory:
        x: 403
        'y': 392
      sql_query_all_rows:
        x: 224
        'y': 82
      ready_to_ship:
        x: 397
        'y': 75
        navigate:
          0b1c0a25-f1e0-49c6-1a23-9926e22b6e56:
            targetId: 430127d5-b68a-529a-8fc7-a4611f39fbe8
            port: 'FALSE'
      get_time:
        x: 397
        'y': 230
      sleep:
        x: 213
        'y': 227
      update_income:
        x: 214
        'y': 389
    results:
      SUCCESS:
        430127d5-b68a-529a-8fc7-a4611f39fbe8:
          x: 733
          'y': 74
