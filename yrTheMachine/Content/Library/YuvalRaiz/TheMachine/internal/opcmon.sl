########################################################################################################################
#!!
#! @input obj_value_pairs: obj=value,[obj=value]
#!!#
########################################################################################################################
namespace: YuvalRaiz.TheMachine.internal
flow:
  name: opcmon
  inputs:
    - machine_id
    - ci
    - node
    - obj_value_pairs
  workflow:
    - opcmon:
        parallel_loop:
          for: "pair in obj_value_pairs.split(',')"
          do:
            io.cloudslang.base.cmd.run_command:
              - command: "${'''%s %s -object %s:%s -option node=%s -option CIH=%s''' % (get_sp('YuvalRaiz.TheMachine.opcmon'),pair,machine_id,ci.replace(' ','_'),node,ci.replace(' ','_'))}"
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      opcmon:
        x: 55
        'y': 116
        navigate:
          c5337619-c661-742c-3922-e9135e210c78:
            targetId: 3deb645d-30d6-fa11-b01b-1a727c456d30
            port: SUCCESS
    results:
      SUCCESS:
        3deb645d-30d6-fa11-b01b-1a727c456d30:
          x: 323
          'y': 118
