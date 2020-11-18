namespace: YuvalRaiz.TheMachine.internal
flow:
  name: opcmsg
  inputs:
    - machine_id
    - ci
    - node
    - eti:
        required: true
    - sev:
        required: true
    - msg:
        required: true
  workflow:
    - opcmsg:
        do:
          io.cloudslang.base.cmd.run_command:
            - command: "${'''%s msg_grp=TheMachine a=%s o=%s msg_t=\"%s\" sev=%s node=%s -option CIH=%s -option ETI=%s''' % (get_sp('YuvalRaiz.TheMachine.opcmsg'),ci,machine_id,msg,sev,node,ci,eti)}"
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      opcmsg:
        x: 55
        'y': 117
        navigate:
          c5337619-c661-742c-3922-e9135e210c78:
            targetId: 3deb645d-30d6-fa11-b01b-1a727c456d30
            port: SUCCESS
    results:
      SUCCESS:
        3deb645d-30d6-fa11-b01b-1a727c456d30:
          x: 323
          'y': 118
