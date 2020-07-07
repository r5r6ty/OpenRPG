import json
import os

filename = 'girl.json'
with open(filename) as f:
    db_data = json.load(f)

    sk = db_data['skeleton']
    sk['spine'] = "3.6"

    bone_name_list = []
    bones = db_data['bones']
    for bone_dict in bones:
    	if bone_dict['name'] != "root":
    		bone_name_list.append(bone_dict['name'])

    anis = db_data['animations']
    for ani in anis.values():
    	ani_data = ani['bones']
    	for bone_name in bone_name_list:
    			if ani_data.has_key(bone_name):
    				ani_bone_data = ani_data[bone_name]
    				if not ani_bone_data.has_key("translate"):
    					ani_bone_data['translate'] = [{"time":0,"x":0,"y":0}]
    				if not ani_bone_data.has_key("rotate"):
    					ani_bone_data['rotate'] = [{"time":0,"angle":0}]
    			else:
    				ani_data[bone_name] = {"translate":[{"time":0,"x":0,"y":0}],"rotate":[{"time":0,"angle":0}]}

    with open("girl.json", "w+") as tmp_file:
			json.dump(db_data, tmp_file)
