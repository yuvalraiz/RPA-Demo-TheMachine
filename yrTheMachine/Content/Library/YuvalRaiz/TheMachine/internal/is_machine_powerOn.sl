namespace: YuvalRaiz.TheMachine.internal
flow:
  name: is_machine_powerOn
  workflow:
    - sql_query:
        do:
          io.cloudslang.base.database.sql_query:
            - db_server_name: "${get_sp('YuvalRaiz.TheMachine.db_hostname')}"
            - db_type: PostgreSQL
            - username: "${get_sp('YuvalRaiz.TheMachine.db_username')}"
            - password:
                value: "${get_sp('YuvalRaiz.TheMachine.db_password')}"
                sensitive: true
            - database_name: "${get_sp('YuvalRaiz.TheMachine.db_name')}"
            - db_url: "${'''jdbc:postgresql://%s:5432/%s''' % (db_server_name,database_name)}"
            - command: select power from public.machine_general;
            - trust_all_roots: 'true'
            - key: tz
        publish:
          - power: "${'on' if return_result.split(',')[0]=='t' else 'off'}"
        navigate:
          - HAS_MORE: is_true
          - NO_MORE: is_true
          - FAILURE: on_failure
    - is_true:
        do:
          io.cloudslang.base.utils.is_true:
            - bool_value: "${str(power=='on')}"
        navigate:
          - 'TRUE': PowerOn
          - 'FALSE': PowerOff
  outputs:
    - power: '${power}'
  results:
    - FAILURE
    - PowerOn
    - PowerOff
extensions:
  graph:
    steps:
      sql_query:
        x: 148
        'y': 121
      is_true:
        x: 352
        'y': 127
        navigate:
          44b149b4-926e-141b-0334-4aa358936879:
            targetId: 6f0b2b83-75d0-de3a-9599-bf5b9a1ebe00
            port: 'FALSE'
          7200531b-5341-7066-efe1-7d70dcce7748:
            targetId: ac33539d-cf7d-7d0a-4192-0418a4e4119c
            port: 'TRUE'
    results:
      PowerOn:
        ac33539d-cf7d-7d0a-4192-0418a4e4119c:
          x: 566
          'y': 65
      PowerOff:
        6f0b2b83-75d0-de3a-9599-bf5b9a1ebe00:
          x: 570
          'y': 219
