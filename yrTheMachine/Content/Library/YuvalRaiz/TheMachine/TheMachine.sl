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
          - SUCCESS: SUCCESS
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
  results:
    - FAILURE
    - SUCCESS
    - Machine_PowerOff
extensions:
  graph:
    steps:
      is_machine_powerOn:
        x: 48
        'y': 91
      get_time:
        x: 198
        'y': 98
      get_all_stations:
        x: 320
        'y': 97
      work_in_station:
        x: 437
        'y': 95
      transfer_to_shop:
        x: 588
        'y': 94
      update_bvd_with_warehouse:
        x: 589
        'y': 256
        navigate:
          90ccf2db-0817-dccc-9d47-032702213933:
            targetId: 1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12
            port: SUCCESS
      update_bvd_with_power:
        x: 51
        'y': 241
        navigate:
          4f154c2e-8c8c-3399-8770-9d4373eef7ad:
            targetId: 16f16afc-670a-fc43-8bc8-34a2753cf870
            port: SUCCESS
      update_bvd_with_power_1:
        x: 442
        'y': 232
    results:
      SUCCESS:
        1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12:
          x: 766
          'y': 250
      Machine_PowerOff:
        16f16afc-670a-fc43-8bc8-34a2753cf870:
          x: 153
          'y': 359
