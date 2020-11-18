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
    - efficiency
    - possible_assembly
  python_action:
    use_jython: false
    script: "import random\n\n#\n# This is the new version\n#\n# do not remove the execute function \ndef execute(machine_id,station_id,station_name,station_hostname,tz,power,max_production_in_cycle,inaccuracy,efficiency,possible_assembly): \n    state=''\n    try_assembly=0\n    created_items=0\n    accuracy=100\n    productivity_level=0\n    msg=''\n    ci=station_name\n    node=station_hostname\n    eti='Productivity_Availability'\n    sev='normal'\n    obj_value_pairs=''\n    \n    if power!='on':\n        state='poweroff'\n        msg='Station '+station_name+' is offline'\n        sev='critical'\n    elif int(possible_assembly)==0:\n        state='missing_items'\n        msg='Station '+station_name+' does not have enough inputs to work'\n        sev='major'\n    else:\n        state='active'\n        try_assembly=min(int(max_production_in_cycle),int(possible_assembly))\n        if inaccuracy == '0':\n            accuracy=100\n        else:\n            accuracy = random.randrange(100 - int(inaccuracy),100)\n        created_items=int(try_assembly * (accuracy / 100) * (int(efficiency) / 100))\n        productivity_level=int(created_items/int(max_production_in_cycle)*100)\n        msg='Station '+station_name+' created '+str(created_items)+' new items efficiency is '+str(productivity_level)+'%'\n        obj_value_pairs='''try_assembly=%s,created_items=%s,productivity_level=%s''' % (try_assembly,created_items,productivity_level)\n    bvd_json='''{\n       \"viewName\": \"%s\",\n       \"ciName\": \"%s\",\n       \"tz\": \"%s\",\n       \"state\": \"%s\",\n       \"productivity_level\": \"%s\",\n       \"created_items\": \"%s\"\n    }''' % (machine_id,station_name,tz,state,productivity_level,created_items)\n    return locals()"
  outputs:
    - created_items
    - try_assembly
    - productivity_level
    - ci
    - node
    - msg
    - eti
    - sev
    - obj_value_pairs
    - bvd_json
  results:
    - POWER_OFF: "${state=='poweroff'}"
      CUSTOM_0: "${state=='poweroff'}"
    - MISSING_PARTS: "${state=='missing_items'}"
      CUSTOM_0: "${state=='missing_items'}"
    - SUCCESS
