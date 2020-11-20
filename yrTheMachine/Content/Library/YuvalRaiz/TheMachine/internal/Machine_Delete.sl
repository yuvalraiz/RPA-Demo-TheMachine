namespace: YuvalRaiz.TheMachine.internal
flow:
  name: Machine_Delete
  inputs:
    - machine_id: MoneyTransfer
  workflow:
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
            - command: "${'''select fullhostname from  public.machine_hosts where machine_id = '%s'; ''' % (machine_id)}"
            - trust_all_roots: 'true'
            - row_delimiter: ;
        publish:
          - all_nodes: '${return_result}'
        navigate:
          - SUCCESS: update_dns
          - FAILURE: on_failure
    - delete_machine_from_db:
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
                ${'''
                delete from public.machine_part_inventory where machine_id = '%s' ;
                delete from public.machine_outcome where machine_id = '%s' ;
                delete from public.station_runtime_configuration  where machine_id = '%s' ;
                delete from public.station_requirements  where machine_id = '%s' ;
                delete from public.station_configuration  where machine_id = '%s' ;
                delete from public.machine_runtime_configuration  where machine_id = '%s' ;
                delete from public.machine_configuration  where machine_id = '%s' ;
                ''' % (machine_id,machine_id,machine_id,machine_id,machine_id,machine_id,machine_id)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
    - update_dns:
        loop:
          for: "full_hostname in all_nodes.split(';')"
          do:
            io.cloudslang.base.cmd.run_command:
              - command: "${'''/usr/bin/ssh -i /root/Emerging_Key_pair.pem root@%s /home/centos/manageDNS.sh -R %s''' % (get_sp('YuvalRaiz.TheMachine.dns_server'),full_hostname.split('.')[0])}"
          break:
            - FAILURE
        navigate:
          - SUCCESS: delete_machine_from_db
          - FAILURE: delete_machine_from_db
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      get_all_stations:
        x: 58
        'y': 129
      delete_machine_from_db:
        x: 340
        'y': 134
        navigate:
          d3596dda-eb40-c7e3-6aed-1d0bc9da1183:
            targetId: 11d00657-1325-09fc-f346-2965829a82e5
            port: SUCCESS
      update_dns:
        x: 211
        'y': 130
    results:
      SUCCESS:
        11d00657-1325-09fc-f346-2965829a82e5:
          x: 463
          'y': 126
