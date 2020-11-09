########################################################################################################################
#!!
#! @input power: on|off
#!!#
########################################################################################################################
namespace: YuvalRaiz.TheMachine
flow:
  name: TheMachine_CyclePower
  inputs:
    - power:
        private: false
  workflow:
    - control_station:
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
            - command: "${'''update public.machine_general set power = %s;''' % ('false' if power == \"off\" else 'true')}"
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: update_bvd_with_power
          - FAILURE: on_failure
    - update_bvd_with_power:
        do:
          YuvalRaiz.TheMachine.internal.update_bvd_with_power: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      control_station:
        x: 291
        'y': 127
      update_bvd_with_power:
        x: 442
        'y': 132
        navigate:
          cc5146db-c242-5513-e0a2-02ac2d608e48:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: SUCCESS
    results:
      SUCCESS:
        b2272065-50c3-383c-6bc3-3eba17ddaa9a:
          x: 611
          'y': 129
