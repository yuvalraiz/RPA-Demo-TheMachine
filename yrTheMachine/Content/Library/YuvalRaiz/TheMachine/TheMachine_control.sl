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
        required: false
    - all_stations:
        default: "${get('station_id','XXX')}"
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
          - SUCCESS: get_all_stations
          - FAILURE: on_failure
    - control_station:
        loop:
          for: "station_data in all_stations.split(';')"
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
                   values ('%s','%s', '%s', %s); ''' %  (tz,station_data.split(',')[0],go_online, go_efficient)}
              - trust_all_roots: 'true'
          break:
            - FAILURE
        navigate:
          - SUCCESS: rpt_power_status
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
            - command: "${'''select station_id, station_name, station_hostname from public.machine_setup %s''' % ('' if all_stations=='XX' else '''where station_id = '%s' ''' % (all_stations) )}"
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - all_stations: '${return_result}'
        navigate:
          - SUCCESS: control_station
          - FAILURE: on_failure
    - TheMachine:
        do:
          YuvalRaiz.TheMachine.TheMachine: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
          - Machine_PowerOff: SUCCESS
    - rpt_power_status:
        loop:
          for: "station_data in all_stations.split(';')"
          do:
            YuvalRaiz.TheMachine.internal.report:
              - station_name: "${station_data.split(',')[1]}"
              - station_hostname: "${station_data.split(',')[2]}"
              - msg_t: "${'''Station power is %s''' % ('on' if go_online == 'true' else 'off')}"
              - sev: "${'normal' if go_online == 'true' else 'critical'}"
              - ETI: "${'''Productivity_Availability:%s''' % ('normal' if go_online == 'true' else 'critical')}"
          break:
            - FAILURE
        navigate:
          - FAILURE: on_failure
          - SUCCESS: TheMachine
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
        x: 320
        'y': 137
      rpt_power_status:
        x: 466
        'y': 140
      get_all_stations:
        x: 181
        'y': 135
      TheMachine:
        x: 599
        'y': 142
        navigate:
          77b54a2c-18e8-fcf6-eb32-f55b69c3f24c:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: Machine_PowerOff
          f6e1ba89-5534-cc68-3894-7d058e4f61f4:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: SUCCESS
    results:
      SUCCESS:
        b2272065-50c3-383c-6bc3-3eba17ddaa9a:
          x: 797
          'y': 150
