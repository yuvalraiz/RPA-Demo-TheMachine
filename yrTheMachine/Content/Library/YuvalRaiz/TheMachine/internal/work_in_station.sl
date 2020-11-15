namespace: YuvalRaiz.TheMachine.internal
flow:
  name: work_in_station
  inputs:
    - station_id
    - tz:
        required: true
    - bvd_url: "${get_sp('YuvalRaiz.TheMachine.bvd_url')}"
    - api_key: "${get_sp('YuvalRaiz.TheMachine.api_key')}"
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
            - command: "${'''select tz,active, efficient, req_input_per_one,max_produce,max_drop_percentege, parts, station_name, station_hostname\n    from public.machine_control mc,\n    public.machine_setup as ms,\n\t(select sum(quantity) as parts from public.inventory where part_id = '%s') as inv\n    where mc.station_id = '%s' and\n        mc.station_id = ms.station_id\n    order by tz desc limit 1;''' % (str(int(station_id)-1),station_id)}"
            - trust_all_roots: 'true'
            - key: tz
        publish:
          - is_active: "${return_result.split(',')[1]}"
          - efficient: "${return_result.split(',')[2]}"
          - req_input_per_one: "${return_result.split(',')[3]}"
          - max_produce: "${return_result.split(',')[4]}"
          - drop_percentege: "${return_result.split(',')[5]}"
          - input_parts: "${return_result.split(',')[6]}"
          - station_name: "${return_result.split(',')[7]}"
          - station_hostname: "${return_result.split(',')[8]}"
        navigate:
          - HAS_MORE: do_the_work
          - NO_MORE: do_the_work
          - FAILURE: on_failure
    - rpt_offline:
        do:
          YuvalRaiz.TheMachine.internal.report:
            - station_name: '${station_name}'
            - station_hostname: '${station_hostname}'
            - msg_t: "${'''Assembly Station %s is offline''' % (station_id)}"
            - sev: Critical
            - ETI: '${Productivity_Availability:Critical}'
        navigate:
          - FAILURE: on_failure
          - SUCCESS: SUCCESS
    - rpt_no_inputs:
        do:
          YuvalRaiz.TheMachine.internal.report:
            - station_name: '${station_name}'
            - station_hostname: '${station_hostname}'
            - msg_t: "${'Station %s does not have enough inputs' % (station_id)}"
            - sev: major
            - ETI: 'Productivity_Level:Major:0'
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
          - efficiency
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
            - station_name: '${station_name}'
            - station_hostname: '${station_hostname}'
            - msg_t: "${'''Station %s finish doing %s new elements (%s%%)''' % (station_id, new_parts,efficiency)}"
            - sev: normal
            - ETI: "${'''Productivity_Level:Normal:%s''' % (efficiency)}"
        navigate:
          - FAILURE: on_failure
          - SUCCESS: send_to_bvd
    - send_to_bvd:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'''%s/bvd-receiver/api/submit/%s/dims/ciName/tags/assembly_cycle''' % (bvd_url,api_key)}"
            - trust_all_roots: 'true'
            - request_character_set: utf-8
            - body: |-
                ${'''{
                    "ciName": "%s",
                    "new_parts": %s,
                    "used_parts": %s,
                    "effective_drops": %s,
                    "efficiency": %s
                }''' % (station_name,new_parts,used_parts,effective_drops,efficiency)}
            - content_type: application/json
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      sql_query:
        x: 26
        'y': 70
      rpt_offline:
        x: 183
        'y': 232
        navigate:
          a36c5cc1-e982-873d-7d06-8c2838a29f16:
            targetId: 8ebfff54-6cb8-1904-aa21-390110432bfc
            port: SUCCESS
      rpt_no_inputs:
        x: 335
        'y': 232
        navigate:
          4b639c0f-ef71-0bb0-13d4-1570eb4580f6:
            targetId: 8ebfff54-6cb8-1904-aa21-390110432bfc
            port: SUCCESS
      do_the_work:
        x: 259
        'y': 65
      update_inventory:
        x: 412
        'y': 65
      rpt_station_worked:
        x: 582
        'y': 67
      send_to_bvd:
        x: 742
        'y': 75
        navigate:
          e06de728-eb09-005d-a3ab-29a6f7b68659:
            targetId: 430127d5-b68a-529a-8fc7-a4611f39fbe8
            port: SUCCESS
    results:
      SUCCESS:
        8ebfff54-6cb8-1904-aa21-390110432bfc:
          x: 267
          'y': 381
        430127d5-b68a-529a-8fc7-a4611f39fbe8:
          x: 985
          'y': 90
