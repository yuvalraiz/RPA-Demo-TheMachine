namespace: YuvalRaiz.TheMachine.internal
operation:
  name: do_the_work_in_station
  inputs:
    - is_active
    - efficient
    - req_input_per_one
    - max_produce
    - drop_percentege
    - input_parts
  python_action:
    use_jython: false
    script: |-
      import random
      def execute(is_active,efficient,req_input_per_one,max_produce,drop_percentege,input_parts):
          used_parts=0
          new_parts=0
          max_based_on_inputs=0
          efficiency=0
          if is_active!='t':
              return
          if req_input_per_one=='0':
              max_based_on_inputs=int(max_produce)
          else:
              max_based_on_inputs=int(min(int(max_produce), int(input_parts)/int(req_input_per_one)))
          if max_based_on_inputs==0:
              return locals()
          max_based_on_inputs=max_based_on_inputs * int(efficient) /100
          used_parts='0' if req_input_per_one=='0' else str(int(max_based_on_inputs*int(req_input_per_one)))
          if drop_percentege=='0':
              effective_drops=0
          else:
              effective_drops=random.randrange(0,int(drop_percentege))
          new_parts=int(max_based_on_inputs*(100-effective_drops)/100)
          efficiency=int(new_parts/int(max_produce)*100)
          return locals()
  outputs:
    - new_parts
    - used_parts
    - effective_drops
    - max_based_on_inputs
    - efficiency
  results:
    - STATION_OFFLINE: "${is_active!='t'}"
      CUSTOM_0: "${is_active!='t'}"
    - NOT_ENOUGH_INPUTS: "${max_based_on_inputs=='0'}"
      CUSTOM_0: "${max_based_on_inputs=='0'}"
    - SUCCESS
