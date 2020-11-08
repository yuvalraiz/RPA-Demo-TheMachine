namespace: YuvalRaiz.TheMachine
flow:
  name: TheMachine
  workflow:
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
          - SUCCESS: SUCCESS
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_time:
        x: 109
        'y': 102
      work_in_station:
        x: 449
        'y': 113
        navigate:
          bcc65422-ffef-b13a-8ea6-9fbcd2a59dad:
            targetId: 1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12
            port: SUCCESS
      get_all_stations:
        x: 270
        'y': 108
    results:
      SUCCESS:
        1c6d7e82-a9b6-ef9b-dd68-2d6c0613ca12:
          x: 632
          'y': 106
