namespace: YuvalRaiz.TheMachine.internal
operation:
  name: station_actual_work
  inputs:
    - machine_id
    - station_id
    - station_name
    - station_hostname
    - tz
    - power
    - max_production_in_cycle
    - inaccuracy
    - outputs
    - efficiency
    - possible_assembly
  python_action:
    use_jython: false
    script: "import random\n\n#\n# This is the new version\n#\n# do not remove the execute function \ndef execute(machine_id,station_id,station_name,station_hostname,tz,power,max_production_in_cycle,inaccuracy,outputs,efficiency,possible_assembly): \n    state=''\n    consume_amount=0\n    created_main_items=0\n    created_alternative_items=0\n    accuracy=100\n    productivity_level=0\n    msg=''\n    ci=station_name\n    node=station_hostname\n    eti='Productivity_Availability'\n    sev='normal'\n    obj_value_pairs=''\n    inventory_sql=''\n    \n    if power!='on':\n        state='poweroff'\n        msg='Station '+station_name+' is offline'\n        sev='critical'\n    elif int(possible_assembly)==0:\n        state='missing_items'\n        msg='Station '+station_name+' does not have enough inputs to work'\n        sev='major'\n    else:\n        state='active'\n        consume_amount=min(int(max_production_in_cycle),int(possible_assembly))* (int(efficiency) / 100)\n        if inaccuracy == '0':\n            accuracy=100\n            created_main_items=consume_amount\n        else:\n            accuracy = random.randrange(100 - int(inaccuracy),100)\n            created_main_items=int(consume_amount * (accuracy / 100) )\n            created_alternative_items=consume_amount-created_main_items\n\n        inventory_sql='''union values ('%s','%s', '%s'::TIMESTAMP, %s, '%s')''' % (machine_id,station_id,tz,created_main_items,outputs.split('|')[0]) \n        if '|' in outputs and created_alternative_items > 0:\n            inventory_sql='''%s  union values ('%s','%s', '%s'::TIMESTAMP, %s, '%s')''' % (inventory_sql,machine_id,station_id,tz,created_alternative_items,outputs.split('|')[1]) \n                \n        \n        productivity_level=int(created_main_items/int(max_production_in_cycle)*100)\n        msg='Station '+station_name+' created '+str(created_main_items)+' new items efficiency is '+str(productivity_level)+'%'\n        obj_value_pairs='''consume_amount=%s,created_main_items=%s,productivity_level=%s''' % (consume_amount,created_main_items,productivity_level)\n    bvd_json='''{\n       \"viewName\": \"%s\",\n       \"ciName\": \"%s\",\n       \"tz\": \"%s\",\n       \"state\": \"%s\",\n       \"productivity_level\": \"%s\",\n       \"created_items\": \"%s\"\n    }''' % (machine_id,station_name,tz,state,productivity_level,created_main_items)\n    return locals()"
  outputs:
    - created_main_items
    - consume_amount
    - productivity_level
    - ci
    - node
    - msg
    - eti
    - sev
    - obj_value_pairs
    - bvd_json
    - inventory_sql
  results:
    - POWER_OFF: "${state=='poweroff'}"
      CUSTOM_0: "${state=='poweroff'}"
    - MISSING_PARTS: "${state=='missing_items'}"
      CUSTOM_0: "${state=='missing_items'}"
    - SUCCESS
