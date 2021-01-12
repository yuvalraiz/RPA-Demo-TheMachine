namespace: YuvalRaiz.TheMachine.internal
operation:
  name: build_inventory_msg_to_bvd
  inputs:
    - machine_id
    - inventory_data
    - row_split: ;
    - col_split: ;
  python_action:
    use_jython: false
    script: "def execute(machine_id,inventory_data,row_split,col_split):\r\n\tbvd_body =  '{\"viewName\" : \"%s\"' % (machine_id)\r\n\tfor item in inventory_data.split(row_split):\r\n        try:\r\n\t\t    bvd_body = '''%s, \"%s\": \"%s\"'''  % ( bvd_body, item.split(col_split)[0], item.split(col_split)[2])\r\n        except:\r\n            error_item = item\r\n\tbvd_body = bvd_body+'}'    \r\n\treturn locals()"
  outputs:
    - bvd_body
  results:
    - SUCCESS
