namespace: YuvalRaiz.TheMachine.Build_A_Machine
flow:
  name: test
  workflow:
    - Build_A_Machine:
        do:
          YuvalRaiz.TheMachine.Build_A_Machine.Build_A_Machine:
            - machine_id: Banking
            - outcome_price: '10'
            - shipment_size: '1'
            - control_name: banking_control
            - hostname_patren: banksrv
            - host_domain: null
            - ip_subnet: 10.99.4
            - stations_names: 'CalcRates|Clac2'
            - stations_max_production: '1|1'
            - stations_output: 'new_rate|price'
            - stations_inputs: 'rates=2|new_rate=1,external_info=1'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      Build_A_Machine:
        x: 273
        'y': 199
        navigate:
          42b9e448-7896-01f8-9216-eb4616cf11ae:
            targetId: 18c37ecf-cff6-27f5-7149-0967683659df
            port: SUCCESS
    results:
      SUCCESS:
        18c37ecf-cff6-27f5-7149-0967683659df:
          x: 396
          'y': 182
