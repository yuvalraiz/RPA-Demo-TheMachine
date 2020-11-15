namespace: YuvalRaiz.TheMachine.internal
flow:
  name: Machine_Consume_Outcomes
  inputs:
    - machine_id
    - shipment_size
    - outcome_price
  workflow:
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
          - HAS_MORE: is_true
          - NO_MORE: is_true
          - FAILURE: on_failure
    - is_true:
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
            - total_items_shipped: '${str(int(num_of_shipments)*int(shipment_size))}'
            - total_price: '${str(int(outcome_price)*int(total_items_shiped))}'
        publish:
          - num_of_shipments
          - total_items_shipped
          - totoal_price: '${total_income}'
        navigate:
          - SUCCESS: update_inventory
          - FAILURE: on_failure
    - send_machine_sales_outcome:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/tags/machine_shippment/dims/machine_id''' % (bvd_url,bvd_api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: |-
                ${'''{"num_of_shipments": "%s",
                "total_items_shipped": "%s",
                "total_price": "%s" } ''' % (num_of_shipments,total_items_shipped,total_price)}
            - content_type: application/json
        navigate:
          - SUCCESS: opcmon
          - FAILURE: on_failure
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
                values ('%s','%s', '%s'::TIMESTAMP, %s, 'shipment')
                )
                ;''' % (machine_id,part_id, tz, total_items_shipped)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: send_machine_sales_outcome
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_machine_current_data:
        x: 46
        'y': 109
      is_true:
        x: 245
        'y': 110
        navigate:
          8afa5036-1162-0e6f-d9da-7b8e30d5fdc5:
            targetId: c5bac99e-9fb5-49ca-5426-9ba0e4a9bb68
            port: 'FALSE'
      opcmon:
        x: 832
        'y': 108
        navigate:
          49f31798-1d65-4614-89e9-2fc2af3de8aa:
            targetId: c5bac99e-9fb5-49ca-5426-9ba0e4a9bb68
            port: SUCCESS
      send_machine_sales_outcome:
        x: 686
        'y': 104
      calc_number_of_shipments:
        x: 417
        'y': 105
      update_inventory:
        x: 565
        'y': 104
    results:
      SUCCESS:
        c5bac99e-9fb5-49ca-5426-9ba0e4a9bb68:
          x: 538
          'y': 313
