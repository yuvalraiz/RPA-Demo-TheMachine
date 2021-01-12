########################################################################################################################
#!!
#! @input ip_subnet: 10.99.2
#! @input stations_names: name1|name2....
#! @input stations_output: outputname1[,alertnativeoutput1]|outputname2[,alertnativeoutput2]....
#! @input stations_inputs: [input1.1=value[,input1.2=value]|input2.1=value.....
#!!#
########################################################################################################################
namespace: YuvalRaiz.TheMachine.Build_A_Machine
flow:
  name: Build_A_Machine
  inputs:
    - machine_id: ProductionLine
    - outcome_price: '165'
    - shipment_size: '40'
    - control_name: prod_line_control
    - hostname_patren: prodstation
    - host_domain: demo.mfdemos.com
    - ip_subnet: 10.99.2
    - stations_names: 'station1|station2|station3'
    - stations_max_production: '100|100|60'
    - stations_output: 'item1|item2|item3'
    - stations_inputs: 'item0=1|item1=1|item2=2'
  workflow:
    - get_time:
        do:
          io.cloudslang.base.datetime.get_time:
            - date_format: 'YYYY-M-dd HH:mm:ss'
        publish:
          - tz: '${output}'
        navigate:
          - SUCCESS: generate_build_content
          - FAILURE: create_machine_in_db
    - create_machine_in_db:
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
            - command: '${sql_commands}'
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: update_dns
          - FAILURE: on_failure
    - update_dns:
        do:
          io.cloudslang.base.cmd.run_command:
            - command: "${'''ssh -i /root/Emerging_Key_pair.pem root@%s /mfdemos_scripts/manage_dns.py --bulk %s %s %s %s ''' % (get_sp('YuvalRaiz.TheMachine.dns_server'),hostname_patren,num_of_hosts,ip_subnet.split('.')[2],machine_id)}"
        navigate:
          - SUCCESS: create_objects
          - FAILURE: on_failure
    - generate_build_content:
        do:
          YuvalRaiz.TheMachine.internal.generate_build_content:
            - machine_id: '${machine_id}'
            - control_name: '${control_name}'
            - outcome_price: '${outcome_price}'
            - shipment_size: '${shipment_size}'
            - stations_names: '${stations_names}'
            - stations_max_production: '${stations_max_production}'
            - stations_output: '${stations_output}'
            - stations_inputs: '${stations_inputs}'
            - hostname_patren: '${hostname_patren}'
            - host_domain: '${host_domain}'
            - ip_subnet: '${ip_subnet}'
            - tz: '${tz}'
        publish:
          - sql_commands
          - cmdb_json
          - num_of_hosts
        navigate:
          - UNEVEN_STATION_DATA: FAILURE
          - SUCCESS: create_objects
    - create_objects:
        do:
          YuvalRaiz.UCMDB.create_objects:
            - ucmdb_url: "${get_sp('YuvalRaiz.TheMachine.ucmdb_url')}"
            - username: "${get_sp('YuvalRaiz.TheMachine.ucmdb_username')}"
            - password:
                value: "${get_sp('YuvalRaiz.TheMachine.ucmdb_password')}"
                sensitive: true
            - ucmdb_objects_json: '${cmdb_json}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
  results:
    - SUCCESS
    - FAILURE
extensions:
  graph:
    steps:
      get_time:
        x: 54
        'y': 165
      create_machine_in_db:
        x: 348
        'y': 157
      update_dns:
        x: 342
        'y': 319
      generate_build_content:
        x: 183
        'y': 164
        navigate:
          57d1a9d8-92e2-dac8-044b-3949bb3f39fe:
            targetId: 85bcad5b-3e27-4ee4-324d-f3e9824c2801
            port: UNEVEN_STATION_DATA
      create_objects:
        x: 511
        'y': 342
        navigate:
          0d8950f6-5d2b-a500-762b-1072ceea4cc9:
            targetId: 3a68c9e4-8e14-eb90-9cbd-d45b48dec484
            port: SUCCESS
    results:
      SUCCESS:
        3a68c9e4-8e14-eb90-9cbd-d45b48dec484:
          x: 619
          'y': 191
      FAILURE:
        85bcad5b-3e27-4ee4-324d-f3e9824c2801:
          x: 183
          'y': 401
