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
      should_invoke_cycle:
        x: 377
        'y': 151
        navigate:
          9a5c3e67-e06c-a58b-e86d-f80ddc53e566:
            targetId: 9c3369bc-b987-ca03-e0c1-91ef075adf8c
            port: 'FALSE'
      get_time:
        x: 56
        'y': 141
      Machine_Run_A_Cycle:
        x: 561
        'y': 153
        navigate:
          7132fbf5-d35b-65a2-1b79-94c809c8d5c8:
            targetId: 9c3369bc-b987-ca03-e0c1-91ef075adf8c
            port: SUCCESS
          ac9d3556-0211-2115-fcab-ac0021e5bcba:
            targetId: 9c3369bc-b987-ca03-e0c1-91ef075adf8c
            port: Machine_PowerOff
      update_machine_power:
        x: 217
        'y': 142
    results:
      SUCCESS:
        9c3369bc-b987-ca03-e0c1-91ef075adf8c:
          x: 570
          'y': 361
