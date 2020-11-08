namespace: YuvalRaiz.TheMachine.internal
flow:
  name: work_in_station
  inputs:
    - station_id
    - tz:
        required: true
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
            - command: "${'''select tz,active, efficient, req_input_per_one,max_produce,max_drop_percentege, parts, station_hostname\n    from public.machine_control mc,\n    public.machine_setup as ms,\n\t(select sum(quantity) as parts from public.inventory where part_id = '%s') as inv\n    where mc.station_id = '%s' and\n        mc.station_id = ms.station_id\n    order by tz desc limit 1;''' % (str(int(station_id)-1),station_id)}"
            - trust_all_roots: 'true'
            - key: tz
        publish:
          - is_active: "${return_result.split(',')[1]}"
          - efficient: "${return_result.split(',')[2]}"
          - req_input_per_one: "${return_result.split(',')[3]}"
          - max_produce: "${return_result.split(',')[4]}"
          - drop_percentege: "${return_result.split(',')[5]}"
          - input_parts: "${return_result.split(',')[6]}"
          - station_hostname: "${return_result.split(',')[7]}"
        navigate:
          - HAS_MORE: do_the_work
          - NO_MORE: do_the_work
          - FAILURE: on_failure
    - rpt_offline:
        do:
          YuvalRaiz.TheMachine.internal.report:
            - station_hostname: '${station_hostname}'
            - msg_t: "${'''Assembly Station %s is offline''' % (station_id)}"
            - station_id: '${station_id}'
            - sev: Critical
            - msg: "${'Station %s is not working' % (station_id)}"
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
    - rpt_no_inputs:
        do:
          YuvalRaiz.TheMachine.internal.report:
            - station_hostname: '${station_hostname}'
            - msg_t: "${'Station %s does not have enough inputs' % (station_id)}"
            - sev: major
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
    - do_the_work:
        do:
          YuvalRaiz.TheMachine.internal.do_the_work_in_station:
            - is_active: '${is_active}'
            - efficient: '${efficient}'
            - req_input_per_one: '${req_input_per_one}'
            - max_produce: '${max_produce}'
            - drop_percentege: '${drop_percentege}'
            - input_parts: '${input_parts}'
        publish:
          - new_parts
          - used_parts
          - effective_drops
        navigate:
          - STATION_OFFLINE: rpt_offline
          - NOT_ENOUGH_INPUTS: rpt_no_inputs
          - SUCCESS: update_inventory
    - update_inventory:
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
                ${'''insert into public.inventory (tz,part_id,quantity)
                   values
                   %s
                   ('%s',%s,%s);''' % ('' if used_parts=='0' else '''('%s',%s,-%s),''' % (tz,str(int(station_id)-1),used_parts), tz,station_id,new_parts)}
            - trust_all_roots: 'true'
        navigate:
          - SUCCESS: rpt_station_worked
          - FAILURE: on_failure
    - rpt_station_worked:
        do:
          YuvalRaiz.TheMachine.internal.report:
            - station_hostname: '${station_hostname}'
            - msg_t: "${'Station %s finish doing %s new elements' % (station_id, new_parts)}"
            - sev: normal
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      sql_query:
        x: 24
        'y': 74
      rpt_offline:
        x: 183
        'y': 232
        navigate:
          a36c5cc1-e982-873d-7d06-8c2838a29f16:
            targetId: 8ebfff54-6cb8-1904-aa21-390110432bfc
            port: SUCCESS
      rpt_no_inputs:
        x: 334
        'y': 233
        navigate:
          4b639c0f-ef71-0bb0-13d4-1570eb4580f6:
            targetId: 8ebfff54-6cb8-1904-aa21-390110432bfc
            port: SUCCESS
      do_the_work:
        x: 257
        'y': 65
      update_inventory:
        x: 448
        'y': 88
      rpt_station_worked:
        x: 657
        'y': 93
        navigate:
          26deefb4-27de-ce5a-cbe8-8c0911f773c9:
            targetId: 430127d5-b68a-529a-8fc7-a4611f39fbe8
            port: SUCCESS
    results:
      SUCCESS:
        8ebfff54-6cb8-1904-aa21-390110432bfc:
          x: 267
          'y': 381
        430127d5-b68a-529a-8fc7-a4611f39fbe8:
          x: 805
          'y': 77