########################################################################################################################
#!!
#! @input power: on|off
#! @input istant_run: true|false (empty = true)
#!!#
########################################################################################################################
namespace: YuvalRaiz.TheMachine
flow:
  name: Machine_Set_Power
  inputs:
    - machine_id
    - power
    - istant_run:
        required: false
    - _invoke_cycle:
        default: "${get('istant_run','true')}"
        private: true
  workflow:
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: update_machine_power
          - FAILURE: on_failure
    - update_machine_power:
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
                ${'''insert into public.machine_runtime_configuration (machine_id,tz,power)
                values ('%s','%s', '%s');''' % (machine_id,tz, 'off' if power == 'off' else 'on')}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: should_invoke_cycle
          - FAILURE: on_failure
    - Machine_Run_A_Cycle:
        do:
          YuvalRaiz.TheMachine.Machine_Run_A_Cycle:
            - machine_id: '${machine_id}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
          - Machine_PowerOff: SUCCESS
    - should_invoke_cycle:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: "${str(_invoke_cycle=='true')}"
        navigate:
          - 'TRUE': Machine_Run_A_Cycle
          - 'FALSE': SUCCESS
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_time:
        x: 100
        'y': 250
      update_machine_power:
        x: 400
        'y': 250
      should_invoke_cycle:
        x: 700
        'y': 250
        navigate:
          97818a4c-4662-aca8-f8b1-7b7e6c270200:
            targetId: 7e5555a7-6a11-75cc-862a-b132cd18517a
            port: 'FALSE'
      Machine_Run_A_Cycle:
        x: 1000
        'y': 125
        navigate:
          382ecdd2-c316-7da1-37d6-b005251207c2:
            targetId: 7e5555a7-6a11-75cc-862a-b132cd18517a
            port: SUCCESS
          fbf13469-3fb1-a5a5-943b-34999c194683:
            targetId: 7e5555a7-6a11-75cc-862a-b132cd18517a
            port: Machine_PowerOff
    results:
      SUCCESS:
        7e5555a7-6a11-75cc-862a-b132cd18517a:
          x: 1000
          'y': 375
