namespace: YuvalRaiz.TheMachine
flow:
  name: TheMachine
  workflow:
    - is_machine_powerOn:
        do:
          YuvalRaiz.TheMachine.internal.is_machine_powerOn: []
        publish:
          - power
        navigate:
          - FAILURE: on_failure
          - PowerOn: get_time
          - PowerOff: update_bvd_with_power
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: get_all_stations
          - FAILURE: on_failure
    - get_all_stations:
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
            - command: select station_id from public.machine_setup order by station_id
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - all_stations: '${return_result}'
        navigate:
          - SUCCESS: work_in_station
          - FAILURE: on_failure
    - work_in_station:
        loop:
          for: "station_id in all_stations.split(';')"
          do:
            YuvalRaiz.TheMachine.internal.work_in_station:
              - station_id: '${station_id}'
              - tz: '${tz}'
          break:
            - FAILURE
        navigate:
          - FAILURE: on_failure
          - SUCCESS: update_bvd_with_power_1
    - transfer_to_shop:
        do:
          YuvalRaiz.TheMachine.internal.transfer_to_shop: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: update_bvd_with_warehouse
    - update_bvd_with_warehouse:
        do:
          YuvalRaiz.TheMachine.internal.update_bvd_with_warehouse: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: update_bvd_with_shipments
    - update_bvd_with_power:
        do:
          YuvalRaiz.TheMachine.internal.update_bvd_with_power: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: Machine_PowerOff
    - update_bvd_with_power_1:
        do:
          YuvalRaiz.TheMachine.internal.update_bvd_with_power: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: transfer_to_shop
    - update_bvd_with_shipments:
        do:
          YuvalRaiz.TheMachine.internal.update_bvd_with_shipments: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
  results:
    - FAILURE
    - SUCCESS
    - Machine_PowerOff
extensions:
  graph:
    steps:
      update_bvd_with_power_1:
        x: 577
        'y': 102
      update_bvd_with_shipments:
        x: 730
        'y': 469
        navigate:
          003294c0-5264-2d06-68ee-a378c3d2bedf:
            targetId: 1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12
            port: SUCCESS
      get_all_stations:
        x: 320
        'y': 97
      transfer_to_shop:
        x: 728
        'y': 105
      work_in_station:
        x: 437
        'y': 95
      update_bvd_with_warehouse:
        x: 730
        'y': 278
      update_bvd_with_power:
        x: 46
        'y': 253
        navigate:
          4f154c2e-8c8c-3399-8770-9d4373eef7ad:
            targetId: 16f16afc-670a-fc43-8bc8-34a2753cf870
            port: SUCCESS
      get_time:
        x: 198
        'y': 98
      is_machine_powerOn:
        x: 48
        'y': 91
    results:
      SUCCESS:
        1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12:
          x: 575
          'y': 470
      Machine_PowerOff:
        16f16afc-670a-fc43-8bc8-34a2753cf870:
          x: 42
          'y': 445
