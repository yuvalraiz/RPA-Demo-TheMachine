namespace: YuvalRaiz.TheMachine.internal
operation:
  name: Generate_SQLs
  inputs:
    - machine_id
    - control_name
    - outcome_price
    - shipment_size
    - stations_names
    - stations_max_production
    - stations_output
    - stations_inputs
    - hostname_patren
    - host_domain
    - ip_subnet
    - tz
  python_action:
    use_jython: false
    script: "# do not remove the execute function \ndef execute(machine_id,control_name,outcome_price,shipment_size,stations_names,stations_max_production,stations_output,stations_inputs,hostname_patren,host_domain,ip_subnet,tz):\n    sql_commands=''\n    values=''\n    hosts_data=''\n    input_names={}\n    names=stations_names.split('|')\n    outputs=stations_output.split('|')\n    max_production_in_cycle=stations_max_production.split('|')\n    inputs=stations_inputs.split('|')\n    num_of_stations=len(names)\n    results=''\n    \n    if num_of_stations!= len(outputs) or num_of_stations != len(inputs) or num_of_stations != len(max_production_in_cycle):    \n        results='uneven data'\n        return locals()\n\n    # machine_configuration\n    #\n    sql_commands = '''insert into public.machine_configuration (machine_id,outcome_price, shipment_size,control_name,control_hostname) \n    values ('%s',%s,%s,'%s','%s');''' % (machine_id, outcome_price, shipment_size, control_name, hostname_patren+str(num_of_stations+1)+'.'+host_domain)\n\n    # machine_runtime_configuration\n    #\n    sql_commands = sql_commands+'''insert into public.machine_runtime_configuration (machine_id,tz,power) \n    values ('%s','%s'::TIMESTAMP, 'on');''' % (machine_id,tz)\n\n    # station_configuration\n    #\n    values=''\n    for i in range(0,len(names)):\n        values='''%s('%s','%s','%s','%s',%s,0,'%s')''' % ('' if len(values) == 0 else values+',', machine_id,i+1,names[i],hostname_patren+str(i+1)+'.'+host_domain,max_production_in_cycle[i],outputs[i])\n        input_names[outputs[i]]='yuval'\n    sql_commands = sql_commands+'insert into public.station_configuration (machine_id,station_id,station_name,station_hostname,max_production_in_cycle,inaccuracy,outcome_part_id) values '+values+';'\n\n    # station_runttime_configuration\n    #\n    values=''\n    for i in range(0,len(names)):\n        values='''%s('%s','%s','%s'::TIMESTAMP,'on',100)''' % ('' if len(values)==0 else values+',',machine_id,i+1,tz)\n    sql_commands = sql_commands+'insert into public.station_runtime_configuration (machine_id,station_id,tz,power,efficiency) values '+values+';'\n\n    # station_requiremnts\n    #\n    values=''\n    for i in range(0,len(names)):\n        for pair in inputs[i].split(','):\n            values='''%s('%s','%s','%s',%s) ''' % ('' if len(values) == 0 else values+',', machine_id, i+1 ,pair.split('=')[0],pair.split('=')[1] )\n            input_names[pair.split('=')[0]]='yuval'\n    sql_commands = sql_commands + 'insert into  public.station_requirements (machine_id,station_id,part_id,required_quantity) values '+values+';'\n    \n    # machine_part_inventory\n    #\n    values=''\n    for n in input_names.keys():\n        values='''%s('%s','%s','%s'::TIMESTAMP, 0,'start')''' % ('' if len(values)==0 else values+',',machine_id,n,tz)\n    sql_commans = sql_commands + 'insert into public.machine_part_inventory (machine_id, part_id, tz,quantity, src) values '+values+';'     \n    \n    for i in range(1,len(names)+2):\n        hosts_data='''%s%s %s.%s''' % ( '' if len(hosts_data)==0 else hosts_data+',', hostname_patren+str(i), ip_subnet, str(i)  )\n\n    return locals()"
  outputs:
    - sql_commands
    - hosts_data
  results:
    - UNEVEN_STATION_DATA: "${results=='uneven data'}"
      CUSTOM_0: "${result=='uneven data'}"
    - SUCCESS
