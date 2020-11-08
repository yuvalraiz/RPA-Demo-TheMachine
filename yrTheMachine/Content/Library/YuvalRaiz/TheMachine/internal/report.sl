namespace: YuvalRaiz.TheMachine.internal
flow:
  name: report
  inputs:
    - station_name
    - station_hostname
    - msg_t:
        required: false
    - sev:
        required: false
    - counter_name:
        required: false
    - counter_value:
        required: false
  workflow:
    - should_send_message:
        do:
          io.cloudslang.base.utils.is_null:
            - variable: '${msg_t}'
        navigate:
          - IS_NULL: should_send_message_1
          - IS_NOT_NULL: opcmsg
    - opcmsg:
        do:
          io.cloudslang.base.cmd.run_command:
            - command: "${'''/opt/OV/bin/opcmsg msg_grp=manufacturer a=manufacturer o=manufacturer msg_t=\"%s\" sev=%s node=%s -option CIH=%s''' % (msg_t,sev,station_hostname,station_name)}"
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
    - should_send_message_1:
        do:
          io.cloudslang.base.utils.is_null:
            - variable: '${counter_name}'
        navigate:
          - IS_NULL: SUCCESS
          - IS_NOT_NULL: opcmon
    - opcmon:
        do:
          io.cloudslang.base.cmd.run_command:
            - command: "${'''/opt/OV/bin/opcmsg msg_grp=manufacturer a=manufacturer o=manufacturer msg_t=\"%s\" sev=%s node=%s''' % (msg_t,sev,station_name)}"
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
extensions:
  graph:
    steps:
      should_send_message:
        x: 65
        'y': 129
      opcmsg:
        x: 353
        'y': 123
        navigate:
          c5337619-c661-742c-3922-e9135e210c78:
            targetId: 3deb645d-30d6-fa11-b01b-1a727c456d30
            port: SUCCESS
      should_send_message_1:
        x: 210
        'y': 284
        navigate:
          25d41b39-e048-00ff-9ec3-2a1c36536b60:
            targetId: 3deb645d-30d6-fa11-b01b-1a727c456d30
            port: IS_NULL
      opcmon:
        x: 356
        'y': 397
        navigate:
          5450e473-b2bc-5ec7-3ad7-29a5eea0096a:
            targetId: 3deb645d-30d6-fa11-b01b-1a727c456d30
            port: SUCCESS
    results:
      SUCCESS:
        3deb645d-30d6-fa11-b01b-1a727c456d30:
          x: 638
          'y': 120
