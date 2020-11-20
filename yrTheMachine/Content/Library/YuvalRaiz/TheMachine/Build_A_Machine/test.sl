namespace: YuvalRaiz.TheMachine.Build_A_Machine
flow:
  name: test
  workflow:
    - Build_A_Machine:
        do:
          YuvalRaiz.TheMachine.Build_A_Machine.Build_A_Machine:
            - machine_id: MoneyTransfer
            - outcome_price: '1'
            - shipment_size: '1'
            - control_name: MoneyTransfer_Control
            - hostname_patren: moneytrns
            - host_domain: null
            - ip_subnet: 10.99.9
            - stations_names: 'cu_gen_transfer|check_digi_sig|check_req|check_fraud|call_cu|trasfer_to_bank'
            - stations_max_production: '10|10|8|9|3|20'
            - stations_output: 'cu_request|digi_ok,digi_reject|req_ok,req_reject|fraud_ok,fraud_reject|cu_ok,cu_fraud|paid,reject'
            - stations_inputs: '|cu_request=1|digi_ok=1|req_ok=1|fraud_reject=1|fraud_ok=1'
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
        x: 274
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
