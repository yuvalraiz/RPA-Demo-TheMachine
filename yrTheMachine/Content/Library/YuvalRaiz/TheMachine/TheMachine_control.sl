########################################################################################################################
#!!
#! @input station_id: leave empty to set all the stations
#! @input online: true|false (true)
#! @input efficient: 0..100 (100)
#!!#
########################################################################################################################
namespace: YuvalRaiz.TheMachine
flow:
  name: TheMachine_control
  inputs:
    - station_id:
        default: '1'
        required: false
    - all_stations:
        default: "${get('station_id','')}"
        private: true
        required: false
    - online:
        default: 'false'
        required: false
    - go_online:
        default: "${get('online','true')}"
        private: true
    - efficient:
        required: false
    - go_efficient:
        default: "${get('efficient','100')}"
        private: true
  workflow:
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: is_null
          - FAILURE: on_failure
    - control_station:
        loop:
          for: "station_id in all_stations.split(';')"
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
                  ${'''insert into   public.machine_control (tz,station_id,active,efficient)
                   values ('%s','%s', '%s', %s); ''' %  (tz,station_id,go_online, go_efficient)}
              - trust_all_roots: 'true'
          break:
            - FAILURE
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
    - is_null:
        do:
          io.cloudslang.base.utils.is_null:
            - variable: '${station_id}'
        publish: []
        navigate:
          - IS_NULL: get_all_stations
          - IS_NOT_NULL: control_station
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
          - SUCCESS: control_station
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_time:
        x: 41
        'y': 132
      control_station:
        x: 408
        'y': 129
        navigate:
          f1616164-ba55-39a7-e902-4c58a7dd5872:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: SUCCESS
      is_null:
        x: 176
        'y': 132
      get_all_stations:
        x: 302
        'y': 242
    results:
      SUCCESS:
        b2272065-50c3-383c-6bc3-3eba17ddaa9a:
          x: 604
          'y': 125
