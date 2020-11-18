namespace: YuvalRaiz.TheMachine.internal
flow:
  name: Machine_Consume_Outcomes
  inputs:
    - machine_id
    - shipment_size
    - outcome_price
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
          - SUCCESS: get_machine_current_data
          - FAILURE: on_failure
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
            - command: "${'''select quantity, part_id  from public.machine_parts_current_level where machine_id = '%s' order by part_id desc limit 1;''' % (machine_id)}"
            - trust_all_roots: 'true'
            - key: machine_id
        publish:
          - outcome_quantity: "${return_result.split(',')[0]}"
          - part_id: "${return_result.split(',')[1]}"
        navigate:
          - HAS_MORE: can_send_shipmment
          - NO_MORE: can_send_shipmment
          - FAILURE: on_failure
    - can_send_shipmment:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: '${str(int(shipment_size)<=int(outcome_quantity))}'
        navigate:
          - 'TRUE': calc_number_of_shipments
          - 'FALSE': SUCCESS
    - calc_number_of_shipments:
        do:
          io.cloudslang.base.utils.do_nothing:
            - num_of_shipments: '${str(int(outcome_quantity)/int(shipment_size))}'
            - total_items_shipped: '${str(int(int(outcome_quantity)/int(shipment_size))*int(shipment_size))}'
            - total_price: '${str((int(outcome_quantity)/int(shipment_size))*int(shipment_size)*int(outcome_price))}'
        publish:
          - num_of_shipments
          - total_items_shipped
          - total_price
        navigate:
          - SUCCESS: update_inventory
          - FAILURE: on_failure
    - send_machine_sales_outcome:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/machine_shippment/dims/viewName''' % (bvd_url,bvd_api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: |-
                ${'''{"viewName": "%s",
                "today_shipments": %s,
                "today_outcome_money": %s,
                "total_shipments": %s,
                "total_outcome_money": %s } ''' % (machine_id,today_shipments,today_outcome_money,total_shipments,total_outcome_money)}
            - content_type: application/json
        navigate:
          - SUCCESS: opcmon
          - FAILURE: opcmon
    - opcmon:
        do:
          YuvalRaiz.TheMachine.internal.opcmon:
            - machine_id: '${machine_id}'
            - ci: '${machine_id}'
            - node: '${machine_id}'
            - obj_value_pairs: "${'''num_of_shipments=%s,total_items_shipped=%s,total_price=%s''' % (num_of_shipments,total_items_shipped,total_price)}"
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
                values ('%s','%s', '%s'::TIMESTAMP, -%s, 'shipment');''' % (machine_id,part_id, tz, total_items_shipped)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: update_outcome
          - FAILURE: on_failure
    - update_outcome:
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
                ${'''insert into public.machine_outcome
                (machine_id,tz,outcome_money,num_of_shipments)
                values ('%s','%s'::TIMESTAMP, %s, %s);''' % (machine_id, tz, total_price, num_of_shipments )}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: get_outcome_report
          - FAILURE: on_failure
    - get_outcome_report:
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
                ${'''select today_shipments, today_outcome_money,total_shipments,total_outcome_money
                from public.machine_outcome_report where machine_id = '%s'; ''' % (machine_id)}
            - trust_all_roots: 'true'
            - delimiter: ;
            - key: machine_id
        publish:
          - today_shipments: "${return_result.split(';')[0]}"
          - today_outcome_money: "${return_result.split(';')[1][2:].replace(',', '')}"
          - total_shipments: "${return_result.split(';')[2]}"
          - total_outcome_money: "${return_result.split(';')[3][2:].replace(',', '')}"
        navigate:
          - HAS_MORE: send_machine_sales_outcome
          - NO_MORE: send_machine_sales_outcome
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      update_inventory:
        x: 637
        'y': 97
      can_send_shipmment:
        x: 307
        'y': 95
        navigate:
          8afa5036-1162-0e6f-d9da-7b8e30d5fdc5:
            targetId: c5bac99e-9fb5-49ca-5426-9ba0e4a9bb68
            port: 'FALSE'
      opcmon:
        x: 766
        'y': 318
        navigate:
          49f31798-1d65-4614-89e9-2fc2af3de8aa:
            targetId: c5bac99e-9fb5-49ca-5426-9ba0e4a9bb68
            port: SUCCESS
      get_outcome_report:
        x: 949
        'y': 90
      send_machine_sales_outcome:
        x: 952
        'y': 325
      get_machine_current_data:
        x: 147
        'y': 76
      get_time:
        x: 19
        'y': 76
      update_outcome:
        x: 790
        'y': 102
      calc_number_of_shipments:
        x: 504
        'y': 101
    results:
      SUCCESS:
        c5bac99e-9fb5-49ca-5426-9ba0e4a9bb68:
          x: 611
          'y': 473
