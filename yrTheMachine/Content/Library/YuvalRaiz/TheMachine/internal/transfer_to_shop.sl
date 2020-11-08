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
          - HAS_MORE: get_amount_of_items
          - NO_MORE: get_amount_of_items
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
    - get_amount_of_items:
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
            - command: "${'''select sum(quantity),part_id from public.inventory  where part_id in (select station_id from public.machine_setup order by station_id desc limit 1) group by part_id;'''}"
            - trust_all_roots: 'true'
            - key: tz
            - min_shippment: '${min_shippment}'
        publish:
          - ready_items: "${return_result.split(',')[0]}"
          - last_station: "${return_result.split(',')[1]}"
          - left_items: '${str(int(ready_items) - int(min_shippment))}'
        navigate:
          - HAS_MORE: ready_to_ship
          - NO_MORE: ready_to_ship
          - FAILURE: on_failure
    - ready_to_ship:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: '${str(int(left_items)>0)}'
        publish: []
        navigate:
          - 'TRUE': get_time
          - 'FALSE': SUCCESS
    - update_income:
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
                ${'''insert into public.income (tz,income) values
                ('%s',%s);''' % (tz,int(min_shippment)*float(current_price))}
            - trust_all_roots: 'true'
            - key: tz
        publish: []
        navigate:
          - HAS_MORE: sleep
          - NO_MORE: sleep
          - FAILURE: on_failure
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
          - SUCCESS: get_amount_of_items
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_shippment_params:
        x: 51
        'y': 86
      get_time:
        x: 506
        'y': 190
      update_income:
        x: 543
        'y': 450
      get_amount_of_items:
        x: 200
        'y': 91
      update_inventory:
        x: 651
        'y': 185
      ready_to_ship:
        x: 386
        'y': 107
        navigate:
          0b1c0a25-f1e0-49c6-1a23-9926e22b6e56:
            targetId: 430127d5-b68a-529a-8fc7-a4611f39fbe8
            port: 'FALSE'
      sleep:
        x: 321
        'y': 282
    results:
      SUCCESS:
        430127d5-b68a-529a-8fc7-a4611f39fbe8:
          x: 727
          'y': 31
