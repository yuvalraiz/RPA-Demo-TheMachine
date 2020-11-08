namespace: YuvalRaiz.TheMachine
flow:
  name: TheMachine
  workflow:
    - is_machine_powerOn:
        do:
          YuvalRaiz.TheMachine.internal.is_machine_powerOn: []
        navigate:
          - FAILURE: on_failure
          - PowerOn: get_time
          - PowerOff: Machine_PowerOff
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
            - command: select station_id from public.machine_setup
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
          - SUCCESS: transfer_to_shop
    - transfer_to_shop:
        do:
          YuvalRaiz.TheMachine.internal.transfer_to_shop: []
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
      is_machine_powerOn:
        x: 37
        'y': 93
        navigate:
          e62b9c53-56c9-6b4f-bb51-882b51036f67:
            targetId: 16f16afc-670a-fc43-8bc8-34a2753cf870
            port: PowerOff
      get_time:
        x: 166
        'y': 95
      get_all_stations:
        x: 292
        'y': 90
      work_in_station:
        x: 437
        'y': 95
      transfer_to_shop:
        x: 630
        'y': 105
        navigate:
          0fffb89c-94c4-0e3a-4d9a-76ad403b019f:
            targetId: 1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12
            port: SUCCESS
    results:
      SUCCESS:
        1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12:
          x: 844
          'y': 80
      Machine_PowerOff:
        16f16afc-670a-fc43-8bc8-34a2753cf870:
          x: 194
          'y': 289
