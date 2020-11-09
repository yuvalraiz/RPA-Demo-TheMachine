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
    - run: 'true'
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
          - SUCCESS: is_true
    - TheMachine:
        do:
          YuvalRaiz.TheMachine.TheMachine: []
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
          - Machine_PowerOff: SUCCESS
    - is_true:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: '${str(power!="off")}'
        navigate:
          - 'TRUE': TheMachine
          - 'FALSE': SUCCESS
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
      TheMachine:
        x: 702
        'y': 265
        navigate:
          57d3fc78-5586-28f0-7d57-0606a596ff33:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: SUCCESS
          6d22ee2a-1f5d-8efa-eb36-5d170d7240fc:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: Machine_PowerOff
      is_true:
        x: 585
        'y': 138
        navigate:
          5fe44032-ca5d-ba11-f553-43f5924ac7f2:
            targetId: b2272065-50c3-383c-6bc3-3eba17ddaa9a
            port: 'FALSE'
    results:
      SUCCESS:
        b2272065-50c3-383c-6bc3-3eba17ddaa9a:
          x: 948
          'y': 93
